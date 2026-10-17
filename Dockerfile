FROM alpine:latest

# Install icecast and ezstream
RUN apk add --no-cache icecast ezstream

# Create required folder structures
RUN mkdir -p /etc/icecast /etc/ezstream /usr/local/icecast/logs

# Generate Icecast Configuration (Logging to stdout to prevent file writing errors)
RUN echo '<icecast> \
    <limits><clients>100</clients><sources>2</sources></limits> \
    <authentication> \
        <source-password>hackme</source-password> \
        <admin-user>admin</admin-user> \
        <admin-password>hackme</admin-password> \
    </authentication> \
    <listen-socket><port>8000</port></listen-socket> \
    <http-headers><header name="Access-Control-Allow-Origin" value="*"/></http-headers> \
    <logging> \
        <accesslog>-</accesslog> \
        <errorlog>-</errorlog> \
        <loglevel>3</loglevel> \
    </logging> \
</icecast>' > /etc/icecast/icecast.xml

# Generate Ezstream Configuration
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

# Copy your playlist file into the container
COPY playlist.txt /etc/ezstream/playlist.txt

# FIX SECURITY: Tighten permissions so Ezstream doesn't complain about "world readable"
RUN chmod 600 /etc/ezstream/ezstream.xml /etc/icecast/icecast.xml

# Start Icecast first, wait, then spin up Ezstream
CMD icecast -c /etc/icecast/icecast.xml & \
    sleep 2 && \
    ezstream -c /etc/ezstream/ezstream.xml
