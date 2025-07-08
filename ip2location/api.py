import time
import re
import ipaddress
import logging
import json
import warnings
from typing import Optional, Dict, Any

# 禁止 pydub 的 ffmpeg 警告
warnings.filterwarnings('ignore', message="Couldn't find ffmpeg or avconv.*", category=RuntimeWarning)

import requests
from flask import Flask, request, jsonify, make_response
from fake_useragent import UserAgent
from pypasser import reCaptchaV3

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)


def get_random_session_id() -> str:
    """
    生成一个随机的 26 位小写字母和数字组成的会话 ID
    """
    import random
    import string

    characters = string.ascii_lowercase + string.digits
    session_id = ''.join(random.choice(characters) for _ in range(26))
    return session_id


def validate_ip_address(ip: str) -> bool:
    """
    验证 IP 地址合法性，支持 IPv4 和 IPv6
    """
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False


def get_recaptcha_response_with_retry(max_retries: int = 3) -> Optional[str]:
    """
    获取 reCAPTCHA 响应，支持重试机制
    """
    url = 'https://www.google.com/recaptcha/api2/anchor?ar=1&k=6LdjXpEUAAAAABG9zEnu_48EEQEdUx4hoqoaDio3&co=aHR0cHM6Ly93d3cuaXAybG9jYXRpb24uY29tOjQ0Mw..&hl=zh-CN&v=h7qt2xUGz2zqKEhSc8DD8baZ&size=invisible&cb=tsydujrrobvx'

    for attempt in range(max_retries):
        try:
            recaptcha_response = reCaptchaV3(url)
            if recaptcha_response:
                return recaptcha_response
        except Exception as e:
            logger.error(f'reCAPTCHA response error: {e}')

        if attempt < max_retries - 1:
            time.sleep(2)

    logger.error('Failed to get reCAPTCHA response')
    return None


def verify_recaptcha_with_retry(session_id: str, ip: str, max_retries: int = 3) -> bool:
    """
    验证 reCAPTCHA token，支持重试机制
    每次验证失败后会重新获取 token，因为 token 只能使用一次
    """
    ua = UserAgent()

    for attempt in range(max_retries):
        try:
            # 每次重试都需要重新获取 token，因为 token 只能使用一次
            token = get_recaptcha_response_with_retry(1)  # 只尝试1次获取 token
            if not token:
                continue

            cookies = {
                '__SECURE-SESSIONID': session_id,
                'first_visit': f'{int(time.time()) - 100}',
            }

            headers = {
                'Accept': 'application/json, text/javascript, */*; q=0.01',
                'Accept-Language': 'zh-CN,zh;q=0.9',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Origin': 'https://www.ip2location.com',
                'Referer': f'https://www.ip2location.com/demo/{ip}',
                'User-Agent': ua.chrome,
                'X-Requested-With': 'XMLHttpRequest',
            }

            data = {
                'action': 'verify',
                'token': token
            }

            response = requests.post('https://www.ip2location.com/demo',
                                     cookies=cookies, headers=headers, data=data, timeout=10)

            if response.status_code == 200:
                result = response.json()
                if result.get('success') == 'true':
                    logger.info(f'IP {ip}: reCAPTCHA verification successful')
                    return True

        except Exception as e:
            logger.error(f'IP {ip}: reCAPTCHA verification error: {e}')

        if attempt < max_retries - 1:
            time.sleep(2)

    logger.error(f'IP {ip}: reCAPTCHA verification failed')
    return False


def extract_ip_info_from_html(html_content: str, target_ip: str) -> Optional[Dict[Any, Any]]:
    """
    从 HTML 内容中提取 IP 信息的 JSON 数据
    """
    try:
        # 使用正则表达式查找 class="language-json" 的代码块
        pattern = r'<code[^>]*class="[^"]*language-json[^"]*"[^>]*>(.*?)</code>'
        match = re.search(pattern, html_content, re.DOTALL)

        if not match:
            logger.error(f'IP {target_ip}: JSON data not found')
            return None

        json_text = match.group(1).strip()

        # 清理 HTML 实体和多余的空格
        json_text = re.sub(r'&quot;', '"', json_text)
        json_text = re.sub(r'&amp;', '&', json_text)
        json_text = re.sub(r'&lt;', '<', json_text)
        json_text = re.sub(r'&gt;', '>', json_text)
        json_text = re.sub(r'\s+', ' ', json_text).strip()

        # 解析 JSON
        ip_info = json.loads(json_text)
        return ip_info

    except Exception as e:
        logger.error(f'IP {target_ip}: HTML parsing error: {e}')
        return None


def get_ip_info(target_ip: str) -> Optional[Dict[Any, Any]]:
    """
    获取指定 IP 地址的详细信息
    """
    logger.info(f'Querying IP {target_ip}')

    # 验证 IP 地址格式
    if not validate_ip_address(target_ip):
        logger.error(f'IP {target_ip}: Invalid IP address format')
        return None

    # 生成会话 ID，在整个流程中保持一致
    session_id = get_random_session_id()

    # 验证 reCAPTCHA（内部会重新获取 token）
    if not verify_recaptcha_with_retry(session_id, target_ip):
        return None

    # 获取 IP 信息页面，使用相同的 session_id
    try:
        ua = UserAgent()

        cookies = {
            '__SECURE-SESSIONID': session_id,
            'first_visit': f'{int(time.time()) - 100}',
        }

        headers = {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9',
            'Referer': 'https://www.ip2location.com/demo',
            'User-Agent': ua.chrome,
        }

        response = requests.get(f'https://www.ip2location.com/demo/{target_ip}',
                                cookies=cookies, headers=headers, timeout=15)

        if response.status_code == 200:
            # 提取 JSON 数据
            ip_info = extract_ip_info_from_html(response.text, target_ip)
            if ip_info:
                logger.info(f'IP {target_ip}: Query successful')
                return ip_info
            else:
                logger.error(f'IP {target_ip}: Data extraction failed')
                return None
        else:
            logger.error(f'IP {target_ip}: Request failed, status code: {response.status_code}')
            return None

    except Exception as e:
        logger.error(f'IP {target_ip}: Query error: {e}')
        return None


def get_client_ip() -> str:
    """
    获取客户端真实 IP 地址
    """
    # 依次检查这些头部，获取真实 IP
    headers_to_check = [
        'X-Forwarded-For',
        'X-Real-IP',
        'X-Forwarded-Proto',
        'CF-Connecting-IP',
        'True-Client-IP'
    ]

    for header in headers_to_check:
        ip = request.headers.get(header)
        if ip:
            # X-Forwarded-For 可能包含多个 IP，取第一个
            if ',' in ip:
                ip = ip.split(',')[0].strip()

            # 验证 IP 格式
            if validate_ip_address(ip):
                return ip

    # 如果没有找到，使用 Flask 的 remote_addr
    return request.remote_addr


def query_ip_info(ip: Optional[str] = None):
    """
    查询 IP 地址信息的统一处理函数
    """
    # 如果没有提供 IP，则获取客户端 IP
    if ip is None:
        target_ip = get_client_ip()
        is_client_ip = True
    else:
        # 验证 IP 地址格式
        if not validate_ip_address(ip):
            logger.warning(f'Invalid IP: {ip}')
            response = make_response(jsonify({
                'success': False,
                'error': 'Invalid IP address format'
            }), 400)
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            return response
        target_ip = ip
        is_client_ip = False

    ip_info = get_ip_info(target_ip)

    if ip_info:
        response = make_response(jsonify({
            'success': True,
            'data': ip_info
        }), 200)

        # 根据是否为客户端 IP 设置不同的缓存策略
        if is_client_ip:
            # 客户端 IP 查询不缓存，因为每个客户端的 IP 都不同
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        else:
            # 指定 IP 查询成功时缓存一周
            response.headers['Cache-Control'] = 'public, max-age=604800'
            response.headers['Expires'] = time.strftime('%a, %d %b %Y %H:%M:%S GMT',
                                                        time.gmtime(time.time() + 604800))
        return response
    else:
        response = make_response(jsonify({
            'success': False,
            'error': 'Unable to retrieve IP information, please try again later'
        }), 500)
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        return response


@app.route('/', methods=['GET'])
def query_client_ip():
    """
    查询客户端 IP 地址信息
    """
    return query_ip_info()


@app.route('/<ip>', methods=['GET'])
def query_specific_ip(ip: str):
    """
    查询指定 IP 地址信息
    """
    return query_ip_info(ip)


@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'success': False,
        'error': 'Route not found'
    }), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f'Server error: {error}')
    return jsonify({
        'success': False,
        'error': 'Internal server error'
    }), 500


if __name__ == '__main__':
    logger.info('Starting API service (port: 5000)')
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)
