# Waveform

An accurate voice waveform and an orb of dots that listens, for iOS and macOS.

Waveform provides three products:

- `WaveformCore` — column and spectrum ring builders, the orb model,
  speech-like synthesis for tests, and the live microphone input seam.
  No UI. The accuracy and the speed live here.
- `WaveformUI` — SwiftUI views: the waveform bar view, the orb of dots,
  and a spectrum orb that draws from reply audio. Built on WaveformCore.
- `WaveformCapture` — one recording engine with two sets of settings:
  Thames streams speech, Ponte transcribes it.

## Platform floors

- macOS 15, iOS 18 (WaveformCore uses Swift's Synchronization atomics)

## Coverage gate

100% line coverage on WaveformCore and WaveformUI library targets.
Run with `scripts/waveform-coverage.sh`.

## Demo

```bash
swift run -c release WaveformApp                      # draw the microphone
swift run -c release WaveformApp --file voice.m4a     # play a file
swift run -c release WaveformApp --snapshot out.png   # write a picture of a made-up voice
```

## Use

```swift
import WaveformCore
import WaveformUI

let ring = ColumnRing(capacity: 8192)
// Feed columns into the ring, then draw:
WaveformView(ring: ring).frame(height: 40)
```
