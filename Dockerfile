FROM alpine:latest

# Install icecast, ezstream, and curl
RUN apk add --no-cache icecast ezstream curl

# Create configuration directories
RUN mkdir -p /etc/icecast /etc/ezstream /var/log/icecast

# Generate Icecast Configuration
RUN echo '<icecast> \
    <limits><clients>100</clients><sources>2</sources></limits> \
    <authentication> \
        <source-password>hackme</source-password> \
        <admin-user>admin</admin-user> \
        <admin-password>hackme</admin-password> \
    </authentication> \
    <listen-socket><port>8000</port></listen-socket> \
    <http-headers><header name="Access-Control-Allow-Origin" value="*"/></http-headers> \
    <logging><logdir>/var/log/icecast</logdir><accesslog>access.log</accesslog><errorlog>error.log</errorlog></logging> \
</icecast>' > /etc/icecast/icecast.xml

# Generate Ezstream Configuration (Forces stream to mount at /radio.mp3)
RUN echo '<ezstream> \
    <url>http://127.0.0</url> \
    <sourcepassword>hackme</sourcepassword> \
    <format>MP3</format> \
    <filename>/etc/ezstream/playlist.txt</filename> \
    <shuffle>0</shuffle> \
    <playlist_program>0</playlist_program> \
    <stream_once>0</stream_once> \
</ezstream>' > /etc/ezstream/ezstream.xml

EXPOSE 8000

# Automatically grab your playlist file
COPY playlist.txt /etc/ezstream/playlist.txt

# Start Icecast in background, wait for boot, then link Ezstream playlist
CMD icecast -c /etc/icecast/icecast.xml & \
    sleep 2 && \
    ezstream -c /etc/ezstream/ezstream.xml
