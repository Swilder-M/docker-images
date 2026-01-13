#!/usr/bin/env python3
'''
GlobalProtect SAML Cookie 获取工具

用法:
    python get_cookie.py <server> [--gateway|--portal] [--clientos=Windows|Linux|Mac]

示例:
    python get_cookie.py vpn.a.edu --gateway
    python get_cookie.py vpn.b.edu --gateway --clientos=Linux
'''

import argparse
import requests
import xml.etree.ElementTree as ET
from base64 import b64decode
from urllib.parse import urlencode
import sys


def get_saml_url(server, interface='gateway', clientos='Windows', verify=True):
    '''获取 SAML 登录 URL'''

    if2prelogin = {
        'portal': 'global-protect/prelogin.esp',
        'gateway': 'ssl-vpn/prelogin.esp'
    }

    endpoint = f'https://{server}/{if2prelogin[interface]}'
    data = {
        'tmp': 'tmp',
        'kerberos-support': 'yes',
        'ipv6-support': 'yes',
        'clientVer': 4100,
        'clientos': clientos,
    }

    print(f'[*] 请求 {endpoint}...', file=sys.stderr)

    try:
        res = requests.post(endpoint, verify=verify, data=data, timeout=30)
        res.raise_for_status()
    except requests.exceptions.SSLError:
        print('[!] SSL 证书验证失败，尝试跳过验证...', file=sys.stderr)
        res = requests.post(endpoint, verify=False, data=data, timeout=30)
    except Exception as e:
        print(f'[!] 请求失败: {e}', file=sys.stderr)
        sys.exit(1)

    # 解析 XML 响应
    try:
        xml = ET.fromstring(res.content)
    except ET.ParseError as e:
        print(f'[!] XML 解析失败: {e}', file=sys.stderr)
        print(f'[!] 响应内容: {res.text[:500]}', file=sys.stderr)
        sys.exit(1)

    if xml.tag != 'prelogin-response':
        print(f'[!] 非预期的响应: {xml.tag}', file=sys.stderr)
        print(f'[!] 请在浏览器中检查: {endpoint}?{urlencode(data)}', file=sys.stderr)
        sys.exit(1)

    # 检查状态
    status = xml.find('status')
    if status is not None and status.text != 'Success':
        msg = xml.find('msg')
        print(f'[!] 错误: {msg.text if msg is not None else "未知错误"}', file=sys.stderr)
        sys.exit(1)

    # 获取 SAML 信息
    sam = xml.find('saml-auth-method')
    sr = xml.find('saml-request')

    if sam is None or sr is None:
        print('[!] 响应中没有 SAML 标签', file=sys.stderr)
        print('[!] 可能此服务器不使用 SAML 认证，或需要尝试其他 clientos', file=sys.stderr)
        sys.exit(1)

    method = sam.text
    saml_data = b64decode(sr.text).decode()

    if method == 'REDIRECT':
        return method, saml_data, None
    elif method == 'POST':
        # POST 方式返回的是 HTML 表单，需要提取 action URL
        return method, None, saml_data
    else:
        print(f'[!] 未知的 SAML 方法: {method}', file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='获取 GlobalProtect SAML 登录 URL')
    parser.add_argument('server', help='GlobalProtect 服务器地址')
    parser.add_argument('-g', '--gateway', dest='interface', action='store_const',
                        const='gateway', default='gateway', help='认证到 gateway (默认)')
    parser.add_argument('-p', '--portal', dest='interface', action='store_const',
                        const='portal', help='认证到 portal')
    parser.add_argument('--clientos', choices=['Windows', 'Linux', 'Mac'],
                        default='Windows', help='客户端操作系统 (默认: Windows)')
    parser.add_argument('--no-verify', action='store_true', help='跳过 SSL 证书验证')

    args = parser.parse_args()

    method, url, html = get_saml_url(
        args.server,
        interface=args.interface,
        clientos=args.clientos,
        verify=not args.no_verify
    )

    print(f'\n[+] SAML 认证方式: {method}', file=sys.stderr)

    if method == 'REDIRECT':
        print('\n' + '=' * 60, file=sys.stderr)
        print('请在浏览器中打开以下 URL 完成登录:', file=sys.stderr)
        print('=' * 60, file=sys.stderr)
        print(f'\n{url}\n', file=sys.stderr)
    else:
        print('\n' + '=' * 60, file=sys.stderr)
        print('这是 POST 方式认证，HTML 内容已保存到 saml_login.html', file=sys.stderr)
        print('请用浏览器打开该文件完成登录', file=sys.stderr)
        print('=' * 60, file=sys.stderr)
        with open('saml_login.html', 'w') as f:
            f.write(html)
        print('\n已保存到: saml_login.html\n', file=sys.stderr)

    print('=' * 60, file=sys.stderr)
    print('登录完成后，获取 Cookie 的方法:', file=sys.stderr)
    print('=' * 60, file=sys.stderr)
    print('''
1. 登录完成后，页面可能显示空白或 "登录成功"

2. 打开浏览器开发者工具 (F12 或 Cmd+Option+I)

3. 切换到 Network 标签，找到最后一个请求（通常是 SAML20/SP/ACS 或类似路径）

4. 查看该请求的 Response Headers，寻找:
   - prelogin-cookie: <这就是你需要的 cookie>
   - saml-username: <用户名>

5. 如果响应头中没有，查看 Response 页面源代码，搜索:
   - prelogin-cookie
   - portal-userauthcookie

6. 获取到 cookie 后，使用以下命令连接 VPN:

   echo '<prelogin-cookie的值>' | sudo openconnect --protocol=gp \\
       --user='<saml-username的值>' \\
       --usergroup=gateway:prelogin-cookie \\
       --passwd-on-stdin \\
       {server}

提示: 页面源代码中的格式类似:
   <!-- <prelogin-cookie>xxx</prelogin-cookie><saml-username>user@example.com</saml-username> -->
'''.format(server=args.server), file=sys.stderr)


if __name__ == '__main__':
    main()
