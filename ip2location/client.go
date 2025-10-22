package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/net/proxy"
)

// IP2LocationClient IP2Location 查询客户端
type IP2LocationClient struct {
	baseURL   string
	client    *http.Client
	sessionID string
	token     string
	defaultIP string
	mu        sync.RWMutex
}

// NewIP2LocationClient 创建新的客户端实例
func NewIP2LocationClient(proxyURL string) (*IP2LocationClient, error) {
	transport := &http.Transport{
		MaxIdleConns:        100,
		MaxIdleConnsPerHost: 10,
		IdleConnTimeout:     90 * time.Second,
	}

	// 如果提供了代理 URL，配置 SOCKS5 代理
	if proxyURL != "" {
		parsedURL, err := url.Parse(proxyURL)
		if err != nil {
			return nil, fmt.Errorf("解析代理 URL 失败: %w", err)
		}

		// 支持 socks5 和 socks5h 协议
		if parsedURL.Scheme == "socks5" || parsedURL.Scheme == "socks5h" {
			// 提取用户名和密码
			var auth *proxy.Auth
			if parsedURL.User != nil {
				username := parsedURL.User.Username()
				password, _ := parsedURL.User.Password()
				auth = &proxy.Auth{
					User:     username,
					Password: password,
				}
			}

			// 创建 SOCKS5 dialer
			dialer, err := proxy.SOCKS5("tcp", parsedURL.Host, auth, proxy.Direct)
			if err != nil {
				return nil, fmt.Errorf("创建 SOCKS5 代理失败: %w", err)
			}

			// 使用 DialContext
			transport.DialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
				return dialer.Dial(network, addr)
			}
		} else {
			return nil, fmt.Errorf("不支持的代理协议: %s (仅支持 socks5 和 socks5h)", parsedURL.Scheme)
		}
	}

	return &IP2LocationClient{
		baseURL: "https://www.ip2location.io",
		client: &http.Client{
			Timeout:   30 * time.Second,
			Transport: transport,
		},
	}, nil
}

// SessionInfo 会话信息
type SessionInfo struct {
	SessionID string
	Token     string
	DefaultIP string
}

// LookupResult 查询结果
type LookupResult struct {
	Status  string      `json:"status"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Result  interface{} `json:"result,omitempty"`
}

// GetSessionInfo 获取 session 信息和 token
func (c *IP2LocationClient) GetSessionInfo() error {
	req, err := http.NewRequest("GET", c.baseURL, nil)
	if err != nil {
		return fmt.Errorf("创建请求失败: %w", err)
	}

	// 设置请求头
	c.setHeaders(req)

	resp, err := c.client.Do(req)
	if err != nil {
		return fmt.Errorf("请求失败: %w", err)
	}
	defer resp.Body.Close()

	// 提取 session ID
	sessionID := c.extractSessionID(resp)
	if sessionID == "" {
		return errors.New("无法获取 session_id")
	}

	// 读取响应体
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取响应失败: %w", err)
	}

	// 解析 HTML 获取 token 和默认 IP
	token, defaultIP, err := c.parseHTMLInfo(string(body))
	if err != nil {
		return err
	}

	// 更新客户端状态
	c.mu.Lock()
	c.sessionID = sessionID
	c.token = token
	c.defaultIP = defaultIP
	c.mu.Unlock()

	return nil
}

// extractSessionID 从响应中提取 session ID
func (c *IP2LocationClient) extractSessionID(resp *http.Response) string {
	for _, cookie := range resp.Cookies() {
		if cookie.Name == "__SECURE-SESSIONID" {
			return cookie.Value
		}
	}
	return ""
}

// parseHTMLInfo 从 HTML 中解析 token 和默认 IP
func (c *IP2LocationClient) parseHTMLInfo(html string) (string, string, error) {
	// 提取默认 IP
	ipRe := regexp.MustCompile(`<input[^>]*id="ip"[^>]*value="([^"]*)"`)
	ipMatches := ipRe.FindStringSubmatch(html)
	var defaultIP string
	if len(ipMatches) > 1 {
		defaultIP = ipMatches[1]
	}

	// 提取 token
	tokenRe := regexp.MustCompile(`<input[^>]*name="token"[^>]*value="([^"]*)"`)
	tokenMatches := tokenRe.FindStringSubmatch(html)
	if len(tokenMatches) < 2 {
		return "", "", errors.New("无法从 HTML 中提取 token")
	}

	return tokenMatches[1], defaultIP, nil
}

// DecodeToken 解码 token
func (c *IP2LocationClient) DecodeToken(tokenValue string) (string, error) {
	// 按分号分割
	parts := strings.Split(tokenValue, ";")
	if len(parts) != 2 {
		return "", errors.New("token 格式不正确")
	}

	tokenPart1 := parts[0]
	tokenPart2, err := strconv.Atoi(parts[1])
	if err != nil {
		return "", fmt.Errorf("token 第二部分格式错误: %w", err)
	}

	// 检查长度
	if len(tokenPart1) < 30 {
		return "", errors.New("token 第一部分长度不足")
	}

	// 按照 JavaScript 算法重组
	part1 := tokenPart1[10:20]              // substr(10, 10)
	part2 := tokenPart1[len(tokenPart1)-10:] // substr(-10)
	part3 := tokenPart1[:10]                // substr(0, 10)

	// 计算 part4
	start := 20
	end := 20 + tokenPart2
	if end > len(tokenPart1) {
		end = len(tokenPart1)
	}
	part4 := tokenPart1[start:end]

	// 组合所有部分
	reassembled := part1 + part2 + part3 + part4

	// 替换 # 为 =
	base64String := strings.ReplaceAll(reassembled, "#", "=")

	// Base64 解码
	decodedBytes, err := base64.StdEncoding.DecodeString(base64String)
	if err != nil {
		return "", fmt.Errorf("Base64 解码失败: %w", err)
	}

	return string(decodedBytes), nil
}

// ValidateToken 验证 token 有效性
func (c *IP2LocationClient) ValidateToken(ipAddress string) (string, error) {
	c.mu.RLock()
	token := c.token
	sessionID := c.sessionID
	c.mu.RUnlock()

	decodedToken, err := c.DecodeToken(token)
	if err != nil {
		return "", fmt.Errorf("token 解码失败: %w", err)
	}

	// 构造请求 URL
	url := fmt.Sprintf("%s/request.json?ip=%s&token=%s", c.baseURL, ipAddress, decodedToken)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return "", err
	}

	// 设置请求头和 Cookie
	c.setHeaders(req)
	req.AddCookie(&http.Cookie{
		Name:  "__SECURE-SESSIONID",
		Value: sessionID,
	})

	resp, err := c.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var result LookupResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("解析响应失败: %w", err)
	}

	if result.Status != "OK" {
		return "", fmt.Errorf("token 验证失败: %s", result.Message)
	}

	return decodedToken, nil
}

// LookupIP 查询 IP 地址信息
func (c *IP2LocationClient) LookupIP(ipAddress string) (interface{}, error) {
	c.mu.RLock()
	token := c.token
	sessionID := c.sessionID
	defaultIP := c.defaultIP
	c.mu.RUnlock()

	// 解码 token
	decodedToken, err := c.DecodeToken(token)
	if err != nil {
		return nil, fmt.Errorf("token 解码失败: %w", err)
	}

	// 如果没有提供 IP，使用默认 IP
	if ipAddress == "" {
		ipAddress = defaultIP
	}

	// 构造请求 URL
	url := fmt.Sprintf("%s/lookup-ip.json?ip=%s&token=%s", c.baseURL, ipAddress, decodedToken)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	// 设置请求头和 Cookie
	c.setHeaders(req)
	req.AddCookie(&http.Cookie{
		Name:  "__SECURE-SESSIONID",
		Value: sessionID,
	})

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result LookupResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if result.Status != "OK" {
		return nil, fmt.Errorf("IP query failed: %s", result.Message)
	}

	// 优先返回 data 字段，如果没有则返回 result 字段
	var dataToReturn interface{}
	if result.Data != nil {
		dataToReturn = result.Data
	} else {
		dataToReturn = result.Result
	}

	// 如果 data 是字符串，尝试解析为 JSON
	if dataStr, ok := dataToReturn.(string); ok {
		var parsedData interface{}
		if err := json.Unmarshal([]byte(dataStr), &parsedData); err == nil {
			return parsedData, nil
		}
	}

	return dataToReturn, nil
}

// setHeaders 设置 HTTP 请求头
func (c *IP2LocationClient) setHeaders(req *http.Request) {
	req.Header.Set("User-Agent", "ip2locationio-app/1.0")
	req.Header.Set("Accept", "application/json, text/javascript, */*; q=0.01")
	req.Header.Set("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8")
	req.Header.Set("Cache-Control", "no-cache")
	req.Header.Set("Pragma", "no-cache")
	req.Header.Set("DNT", "1")
	req.Header.Set("Sec-CH-UA", `"Not)A;Brand";v="8", "Chromium";v="138", "Google Chrome";v="138"`)
	req.Header.Set("Sec-CH-UA-Mobile", "?0")
	req.Header.Set("Sec-CH-UA-Platform", `"macOS"`)
	req.Header.Set("Sec-Fetch-Dest", "empty")
	req.Header.Set("Sec-Fetch-Mode", "cors")
	req.Header.Set("Sec-Fetch-Site", "same-origin")
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
	req.Header.Set("Referer", "https://www.ip2location.io/")
}

// Query 完整的查询流程
func (c *IP2LocationClient) Query(ipAddress string) (interface{}, error) {
	// 1. 获取 session 信息
	if err := c.GetSessionInfo(); err != nil {
		return nil, fmt.Errorf("获取 session 信息失败: %w", err)
	}

	// 2. 验证 token（使用默认 IP 进行初始验证）
	c.mu.RLock()
	defaultIP := c.defaultIP
	c.mu.RUnlock()

	_, err := c.ValidateToken(defaultIP)
	if err != nil {
		return nil, fmt.Errorf("token 验证失败: %w", err)
	}

	// 3. 查询 IP 信息
	result, err := c.LookupIP(ipAddress)
	if err != nil {
		return nil, err
	}

	return result, nil
}
