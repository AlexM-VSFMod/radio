const http = require('http');
const fs = require('fs');
const axios = require('axios');

const PORT = process.env.PORT || 8000;
let listeners = [];
let playlist = [];
let currentTrackIndex = 0;

try {
    playlist = fs.readFileSync('playlist.txt', 'utf-8').split('\n').map(line => line.trim()).filter(Boolean);
    console.log(`Loaded ${playlist.length} songs from playlist.txt.`);
} catch (err) {
    console.error('Playlist file missing!', err);
}

async function startRadio() {
    if (playlist.length === 0) return;
    
    while (true) {
        const url = playlist[currentTrackIndex];
        console.log(`Broadcasting: ${url}`);
        
        try {
            const response = await axios({ method: 'get', url: url, responseType: 'stream' });
            
            await new Promise((resolve) => {
                response.data.on('data', (chunk) => {
                    listeners.forEach(res => {
                        try { res.write(chunk); } catch(e){}
                    });
                });
                response.data.on('end', resolve);
                response.data.on('error', resolve);
            });
        } catch (err) {
            console.error(`Error streaming link: ${url}`);
        }
        
        currentTrackIndex = (currentTrackIndex + 1) % playlist.length;
        await new Promise(r => setTimeout(r, 1000));
    }
}

const server = http.createServer((req, res) => {
    res.writeHead(200, {
        'Content-Type': 'audio/mpeg',
        'Transfer-Encoding': 'chunked',
        'Connection': 'keep-alive',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Access-Control-Allow-Origin': '*'
    });
    listeners.push(res);
    
    req.on('close', () => {
        listeners = listeners.filter(l => l !== res);
    });
});

server.listen(PORT, () => {
    console.log(`Radio server cleanly listening on port ${PORT}`);
    startRadio();
});
