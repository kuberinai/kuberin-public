#!/usr/bin/env python3
import json
import os
import asyncio
from edge_tts import list_voices, Communicate

BASE = "/Users/sumansunkara/.copilot/session-state/a41bbd7f-21fa-469e-8bc9-7b42e18055a8/files/mosaic_perspective"
SEGMENTS_FILE = os.path.join(BASE, "segments.json")
OUTPUT_DIR = os.path.join(BASE, "audio")
os.makedirs(OUTPUT_DIR, exist_ok=True)

async def find_neural_voice():
    all_voices = await list_voices()
    us_neural = [v for v in all_voices if "en-US" in v.get("Locale", "") and "Neural" in v.get("ShortName", "")]
    if us_neural:
        return us_neural[0]["ShortName"]
    neural = [v for v in all_voices if "Neural" in v.get("ShortName", "")]
    if neural:
        return neural[0]["ShortName"]
    return "en-US-AriaNeural"

async def generate_narration():
    voice_name = await find_neural_voice()
    print(f"Using neural voice: {voice_name}")
    
    segments = json.load(open(SEGMENTS_FILE))
    total = len(segments)
    
    for i, seg in enumerate(segments):
        text = seg.get("narration", "")
        if not text:
            print(f"skipping {i}: no narration")
            continue
            
        output_file = f"{OUTPUT_DIR}/seg_{i:02d}.mp3"
        print(f"Generating {i+1}/{total}: {text[:60]}...")
        
        communicate = Communicate(voice=voice_name, text=text)
        await communicate.save(output_file)
        
        size = os.path.getsize(output_file)
        print(f"Generated {output_file} ({size:,} bytes)")

    print(f"\nAll {total} narration files generated in {OUTPUT_DIR}/")

asyncio.run(generate_narration())
