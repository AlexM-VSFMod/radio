FROM alpine:latest

# Install Node.js
RUN apk add --no-cache nodejs npm

WORKDIR /app

# Create server files directly inside the building step
RUN echo '{ \
  "name": "radio", \
  "version": "1.0.0", \
  "main": "server.js", \
  "dependencies": { \
    "axios": "^1.6.0" \
  } \
}' > package.json

RUN npm install

# Write an advanced streaming script directly to the build context
RUN echo "const http = require('http'); \n\
const fs = require('fs'); \n\
const axios = require('axios'); \n\
const PORT = process.env.PORT || 8000; \n\
let listeners = []; \n\
let playlist = []; \n\
let currentTrackIndex = 0; \n\
try { \n\
    playlist = fs.readFileSync('playlist.txt', 'utf-8').split('\\\n').map(line => line.trim()).filter(Boolean); \n\
    console.log('Loaded ' + playlist.length + ' songs.'); \n\
} catch (err) { console.error('Playlist file missing!', err); } \n\
async function startRadio() { \n\
    if (playlist.length === 0) return; \n\
    while (true) { \n\
        const url = playlist[currentTrackIndex]; \n\
        console.log('Broadcasting: ' + url); \n\
        try { \n\
            const response = await axios({ method: 'get', url: url, responseType: 'stream' }); \n\
            await new Promise((resolve) => { \n\
                response.data.on('data', (chunk) => { \n\
                    listeners.forEach(res => { try { res.write(chunk); } catch(e){} }); \n\
                }); \n\
                response.data.on('end', resolve); \n\
                response.data.on('error', resolve); \n\
            }); \n\
        } catch (err) { console.error('Error on link: ' + url); } \n\
        currentTrackIndex = (currentTrackIndex + 1) % playlist.length; \n\
        await new Promise(r => setTimeout(r, 1000)); \n\
    } \n\
} \n\
const server = http.createServer((req, res) => { \n\
    res.writeHead(200, { \n\
        'Content-Type': 'audio/mpeg', \n\
        'Transfer-Encoding': 'chunked', \n\
        'Connection': 'keep-alive', \n\
        'Cache-Control': 'no-cache, no-store', \n\
        'Access-Control-Allow-Origin': '*' \n\
    }); \n\
    listeners.push(res); \n\
    req.on('close', () => { listeners = listeners.filter(l => l !== res); }); \n\
}); \n\
server.listen(PORT, () => { console.log('Radio online on ' + PORT); startRadio(); });" > server.js

# Copy your playlist.txt directly into the container folder
COPY playlist.txt ./playlist.txt

EXPOSE 8000

CMD ["node", "server.js"]
