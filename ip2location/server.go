package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"
)

// Server HTTP 服务器
type Server struct {
	client *IP2LocationClient
	logger *Logger
}

// Logger 日志记录器
type Logger struct {
	mu     sync.Mutex
	output *log.Logger
}

// NewLogger 创建新的日志记录器
func NewLogger() *Logger {
	return &Logger{
		output: log.New(os.Stdout, "", log.LstdFlags),
	}
}

// Info 记录信息日志
func (l *Logger) Info(format string, v ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.output.Printf("[INFO] "+format, v...)
}

// Error 记录错误日志
func (l *Logger) Error(format string, v ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.output.Printf("[ERROR] "+format, v...)
}

// NewServer 创建新的服务器实例
func NewServer(proxyURL string) (*Server, error) {
	client, err := NewIP2LocationClient(proxyURL)
	if err != nil {
		return nil, fmt.Errorf("创建客户端失败: %w", err)
	}

	return &Server{
		client: client,
		logger: NewLogger(),
	}, nil
}

// isValidIP 验证 IP 地址格式
func isValidIP(ip string) bool {
	// IPv4 验证
	if net.ParseIP(ip) != nil {
		return true
	}
	return false
}

// sanitizeIP 清理和验证 IP 地址
func sanitizeIP(ip string) string {
	// 移除前后空格
	ip = strings.TrimSpace(ip)
	// 验证 IP 格式
	if isValidIP(ip) {
		return ip
	}
	return ""
}

// getClientIP 获取客户端 IP
func getClientIP(r *http.Request) string {
	// 尝试从 X-Forwarded-For 获取
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		ips := strings.Split(xff, ",")
		if len(ips) > 0 {
			return strings.TrimSpace(ips[0])
		}
	}

	// 尝试从 X-Real-IP 获取
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return strings.TrimSpace(xri)
	}

	// 从 RemoteAddr 获取
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return ip
}

// respondJSON 返回 JSON 响应
func respondJSON(w http.ResponseWriter, statusCode int, data interface{}, cacheable bool) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	if cacheable {
		// 成功响应，缓存 1 个月
		w.Header().Set("Cache-Control", "public, max-age=2592000, immutable")
	} else {
		// 失败响应，禁止缓存
		w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
		w.Header().Set("Pragma", "no-cache")
		w.Header().Set("Expires", "0")
	}

	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

// respondError 返回错误响应
func respondError(w http.ResponseWriter, statusCode int) {
	respondJSON(w, statusCode, map[string]string{
		"error": "Query failed, please try again later.",
	}, false)
}

// lookupHandler IP 查询处理器
func (s *Server) lookupHandler(w http.ResponseWriter, r *http.Request) {
	// 只允许 GET 请求
	if r.Method != http.MethodGet {
		respondError(w, http.StatusMethodNotAllowed)
		return
	}

	// 从路径中提取 IP 地址
	path := strings.TrimPrefix(r.URL.Path, "/")
	ip := sanitizeIP(path)

	if ip == "" {
		respondError(w, http.StatusBadRequest)
		return
	}

	clientIP := getClientIP(r)
	s.logger.Info("Query IP: %s (from: %s)", ip, clientIP)

	// 查询 IP 信息
	result, err := s.client.Query(ip)
	if err != nil {
		s.logger.Error("Query failed: %s, error: %v", ip, err)
		respondError(w, http.StatusInternalServerError)
		return
	}

	s.logger.Info("Query success: %s", ip)
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"ip":   ip,
		"data": result,
	}, true)
}

// recoveryMiddleware 恢复中间件，捕获 panic
func (s *Server) recoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				s.logger.Error("Panic recovered: %v", err)
				respondError(w, http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// loggingMiddleware 日志中间件
func (s *Server) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		s.logger.Info("%s %s %s %v", getClientIP(r), r.Method, r.URL.Path, time.Since(start))
	})
}

// securityMiddleware 安全中间件
func (s *Server) securityMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// 设置安全响应头
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Content-Security-Policy", "default-src 'self'")

		// 验证路径，防止路径遍历攻击
		if strings.Contains(r.URL.Path, "..") {
			respondError(w, http.StatusBadRequest)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// Run 启动服务器
func (s *Server) Run(port string) error {
	mux := http.NewServeMux()

	// 注册路由
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			respondError(w, http.StatusBadRequest)
			return
		}
		s.lookupHandler(w, r)
	})

	// 应用中间件
	handler := s.recoveryMiddleware(
		s.loggingMiddleware(
			s.securityMiddleware(mux),
		),
	)

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      handler,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 优雅关闭
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint

		s.logger.Info("Received shutdown signal, gracefully shutting down...")
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			s.logger.Error("Server shutdown failed: %v", err)
		}
	}()

	s.logger.Info("Server started successfully, listening on port: %s", port)
	return server.ListenAndServe()
}
