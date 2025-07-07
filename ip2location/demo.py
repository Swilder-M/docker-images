import time

import requests
from pypasser import reCaptchaV3


def get_recaptcha_response():
    url = 'https://www.google.com/recaptcha/api2/anchor?ar=1&k=6LdjXpEUAAAAABG9zEnu_48EEQEdUx4hoqoaDio3&co=aHR0cHM6Ly93d3cuaXAybG9jYXRpb24uY29tOjQ0Mw..&hl=zh-CN&v=h7qt2xUGz2zqKEhSc8DD8baZ&size=invisible&cb=tsydujrrobvx'
    recaptcha_response = reCaptchaV3(url)
    return recaptcha_response


def get_random_session_id():
    """
    生成一个随机的 26 位小写字母和数字组成的会话 ID
    """
    import random
    import string

    characters = string.ascii_lowercase + string.digits
    session_id = ''.join(random.choice(characters) for _ in range(26))
    return session_id


if __name__ == '__main__':
    ip = '182.255.32.10'
    token = get_recaptcha_response()
    cookies = {
        '__SECURE-SESSIONID': get_random_session_id(),
        'first_visit': f'{int(time.time()) - 100}',
    }

    headers = {
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Origin': 'https://www.ip2location.com',
        'Referer': f'https://www.ip2location.com/demo/{ip}',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36',
        'X-Requested-With': 'XMLHttpRequest',
    }

    data = {
        'action': 'verify',
        'token': token
    }
    response = requests.post('https://www.ip2location.com/demo', cookies=cookies, headers=headers, data=data)
    print(response.status_code)
    print(response.headers)
    print(response.text)
    print(response.json())
    if response.json()['success'] == 'true':
        response = requests.get(f'https://www.ip2location.com/demo/{ip}', cookies=cookies, headers=headers)
        print(response.status_code)
        print(response.text)
