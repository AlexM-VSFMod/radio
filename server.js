const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();

// 1. List your local mp3 files in the exact order you want them to play
const playlist = [
    'music/song1.mp3',
    'music/song2.mp3',
    'music/song3.mp3'
];

// Global state to track sync time
let startTime = Date.now();

// Helper to calculate total playlist duration
function getPlaylistDuration() {
    // Note: For absolute perfection, you'd calculate exact track lengths. 
    // For this simple script, we assume an average length or read metadata.
    return playlist.length * 180 * 1000; // Example: 3 mins per song in ms
}

app.get('/radio.mp3', (req, res) => {
    // Tell the Minecraft mod it is receiving an endless raw audio stream
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Transfer-Encoding', 'chunked');

    // Calculate how far into the loop we currently are globally
    const totalElapsed = Date.now() - startTime;
    
    // Hardcoded simple track math (Assuming 180 seconds / 3 mins per track for simplicity)
    const trackDurationMs = 180 * 1000; 
    const currentTrackIndex = Math.floor((totalElapsed / trackDurationMs) % playlist.length);
    const msIntoCurrentTrack = totalElapsed % trackDurationMs;

    const trackPath = path.join(__dirname, playlist[currentTrackIndex]);

    if (!fs.existsSync(trackPath)) {
        res.status(404).send('Audio file missing');
        return;
    }

    // Calculate approximate byte offset to jump to for live sync
    const stats = fs.statSync(trackPath);
    const approxBytesPerMs = stats.size / trackDurationMs;
    const startByte = Math.floor(msIntoCurrentTrack * approxBytesPerMs);

    // Create a read stream starting exactly where the global radio timeline is
    const stream = fs.createReadStream(trackPath, { start: startByte });
    
    // Pipe the raw bytes straight to Glaiden's Audio
    stream.pipe(res);

    req.on('close', () => {
        stream.destroy();
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Glaiden Radio proxy streaming on port ${PORT}`));
