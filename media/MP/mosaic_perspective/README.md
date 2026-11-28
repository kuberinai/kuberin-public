# The Mosaic Perspective - By Mohnish Pabrai

A narrated MP4 video summarizing the key ideas from *The Mothman Perspectives* by Mohnish Pabrai.

## Files

### Audio & Video
- `audio/` - Individual narration files (26 segments, ~12 min total)
- `clips/` - Per-segment video clips with slide backgrounds  
- `img/slide_XX.png` - 1080p slide images
- `Mosaic_Perspective_Multilingual.mp4` - Final narrated video

### Scripts
- `narrate_mosaic.py` - Generates narration using Edge-TTS (AvaNeural voice)
- `segments.json` - All 26 segments with titles, subtitles, and narration

## Usage

```bash
# Generate slides
python3 make_slides.py

# Generate narration (requires pip install edge-tts)
pip install edge-tts
python3 narrate_mosaic.py

# Build final video
ffmpeg -f concat -i clips.txt -c:v libx264 -preset medium -crf 22 -c:a aac -b:a 192k final.mp4
```

## Video Details

- **Duration**: ~12 minutes (735 seconds)
- **Resolution**: 1080p (1920x1080)
- **Voice**: Microsoft AvaNeural (English US neural)
- **Format**: H.264 video + AAC audio
- **Size**: ~19 MB

## Content

The video covers 26 key lessons from Mohnish Pabrai's investment philosophy:

1. Cloning the Masters
2. Lollapalooza Effects in Business
3. The Mosaic Method
4. Focus on Few Bets
5. Expected Value Thinking
6. Bet Big When You Know
7. The Power of Replication
8. Avoid Stupidity First
9. The Duality of Thinking
10. Learn from Mistakes
11. Think in Decades
12. Business Models Matter
13. The Wisdom of Waiting
14. Understand Moats
15. The Value of Knowledge
16. Be Comfortable Being Wrong
17. The Importance of Luck
18. Circle of Competence
19. The Art of Saying No
20. Simplicity in Everything
21. The Compound Effect
22. Embrace Failure Early
23. The Long Game
24-26. Additional lessons on excellence

## Voice Quality

The narration uses Microsoft's highest-quality neural voice (AvaNeural), which provides natural intonation and speech patterns compared to traditional TTS systems.
