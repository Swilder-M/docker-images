package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	// 解析命令行参数
	portFlag := flag.String("port", "5000", "Server listening port")
	proxyFlag := flag.String("proxy", "", "SOCKS5 proxy address (e.g., socks5://user:pass@1.2.3.4:1080 or socks5h://user:pass@1.2.3.4:1080)")
	flag.Parse()

	// 优先使用环境变量
	port := os.Getenv("PORT")
	if port == "" {
		port = *portFlag
	}

	proxy := os.Getenv("FETCH_PROXY")
	if proxy == "" {
		proxy = *proxyFlag
	}

	// 验证端口
	if port == "" {
		fmt.Println("Error: Port cannot be empty")
		os.Exit(1)
	}

	// 创建并启动服务器
	server, err := NewServer(proxy)
	if err != nil {
		fmt.Printf("Failed to create server: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("IP2Location Query Service Starting...\n")
	fmt.Printf("Port: %s\n", port)
	if proxy != "" {
		fmt.Printf("Proxy: %s\n", proxy)
	} else {
		fmt.Printf("Proxy: Direct connection\n")
	}
	fmt.Printf("Access: http://localhost:%s/{ip}\n", port)
	fmt.Printf("Press Ctrl+C to stop\n")
	fmt.Println("=" + string(make([]byte, 50)))

	if err := server.Run(port); err != nil {
		fmt.Printf("Server error: %v\n", err)
		os.Exit(1)
	}
}