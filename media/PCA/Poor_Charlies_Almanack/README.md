# Poor Charlie's Almanack - The Essence

A narrated MP4 video summarizing the key ideas from *Poor Charlie's Almanack*.

## Files

### Audio & Video
- `audio/` - Individual narration files (24 segments, ~15 min total)
- `clips/` - Per-segment video clips with slide backgrounds
- `img/slide_XX.png` - 1080p slide images
- `Poor_Charlies_Almanack_Essence_Multilingual.mp4` - Final narrated video

### Scripts
- `make_slides.py` - Renders slide images using Pillow
- `narrate_edge_v5.py` - Generates narration with Edge-TTS (AvaNeural voice)
- `segments.json` - All 24 segments with titles, subtitles, and narration

## Usage

```bash
# Generate slides
python3 make_slides.py

# Generate narration (requires pip install edge-tts)
pip install edge-tts
python3 narrate_edge_v5.py

# Build final video
ffmpeg -f concat -i clips.txt -c:v libx264 -preset medium -crf 22 -c:a aac -b:a 192k final.mp4
```

## Video Details

- **Duration**: ~15 minutes (938 seconds)
- **Resolution**: 1080p (1920x1080)
- **Voice**: Microsoft AvaNeural (English US neural)
- **Format**: H.264 video + AAC audio
- **Size**: ~27 MB

## Content

The video covers 24 key lessons from Poor Charlie's Almanack, including:
1. The Latticework of Mental Models
2. Invert, Always Invert
3. Lollapalooza Effects
4. Psychology of Human Misjudgment
5. Incentives
... and many more wisdom principles

## Voice Quality

The narration uses Microsoft's highest-quality neural voice (AvaNeural), which provides natural intonation and speech patterns compared to traditional TTS systems.
