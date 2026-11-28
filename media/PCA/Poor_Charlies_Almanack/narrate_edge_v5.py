#!/usr/bin/env python3
"""Generate natural narration using Edge-TTS (Microsoft Neural Voices)."""
import json
import os
import asyncio
from edge_tts import list_voices, Communicate

BASE = os.path.dirname(os.path.abspath(__file__))
SEGMENTS_FILE = os.path.join(BASE, "segments.json")
OUTPUT_DIR = os.path.join(BASE, "audio")
os.makedirs(OUTPUT_DIR, exist_ok=True)

async def find_neural_voice():
    """Find a high-quality neural voice."""
    all_voices = await list_voices()
    
    # Filter for English US neural voices
    us_neural = [v for v in all_voices if "en-US" in v.get("Locale", "") and "Neural" in v.get("ShortName", "")]
    if us_neural:
        return us_neural[0]["ShortName"]
    
    # Fallback to any neural voice
    neural = [v for v in all_voices if "Neural" in v.get("ShortName", "")]
    if neural:
        return neural[0]["ShortName"]
    
    # Default fallback
    return "en-US-AriaNeural"

async def generate_narration():
    """Generate narration for each segment using Edge-TTS."""
    
    voice_name = await find_neural_voice()
    print(f"Using neural voice: {voice_name}")
    
    # Load segments
    segments = json.load(open(SEGMENTS_FILE))
    total = len(segments)
    
    # Generate audio for each segment
    for i, seg in enumerate(segments):
        text = seg["narration"]
        output_file = f"{OUTPUT_DIR}/seg_{i:02d}.mp3"
        
        print(f"Generating {i+1}/{total}: {text[:70]}...")
        
        # Create Communicate instance and save to file
        communicate = Communicate(voice=voice_name, text=text)
        
        # Save directly using async save method
        await communicate.save(output_file)
        
        size = os.path.getsize(output_file)
        print(f"Generated {output_file} ({size:,} bytes)")

    print(f"\nAll {total} narration files generated in {OUTPUT_DIR}/")

if __name__ == "__main__":
    asyncio.run(generate_narration())
