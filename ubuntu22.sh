ubuntu22

apt-get update

apt-get install -y libxml2 libgio-cil kmod libgtk-3-0 x11vnc xvfb net-tools libwebkit2gtk-4.0-dev blackbox bbrun iproute2 iptables busybox-syslogd novnc dante-server inetutils-ping

wget -O cisco-secure-client.tar.gz https://uci.service-now.com/sys_attachment.do\?sys_id\=f16fb94c472d92908fd9485c416d4339

tar -xvf cisco-secure-client.tar.gz
rm cisco-secure-client.tar.gz
mv cisco-secure-client-linux64-5.1.4.74 cisco-secure-client
mkdir -p /usr/share/desktop-directories/
cd /opt/cisco-secure-client/vpn/
bash ./vpn_install.sh

chmod +x entrypoint.sh
chmod +x purge-firewall.sh
chmod +x launch-dante-server.sh





RUN apt-get update && apt-get install -y libxml2 libgio-cil kmod libgtk-3-0 x11vnc xvfb net-tools libwebkit2gtk-4.0-dev blackbox bbrun iproute2 iptables busybox-syslogd novnc dante-server inetutils-ping && apt-get clean

COPY cisco-secure-client /opt/cisco-secure-client

RUN sh /opt/cisco-secure-client/vpn/vpn_install.sh

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 0700 /entrypoint.sh

COPY ./purge-firewall.sh /purge-firewall.sh
RUN chmod 0700 /purge-firewall.sh

COPY ./launch-dante-server.sh /launch-dante-server.sh
RUN chmod 0700 /launch-dante-server.sh

COPY ./menu /etc/X11/blackbox/blackbox-menu

COPY ./danted.conf /etc/danted.conf

ENTRYPOINT ["/entrypoint.sh"]
