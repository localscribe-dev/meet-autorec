"""録音フォルダ（me.wav / them.wav）から話者付きの transcript.txt を作る。

使い方: .venv/bin/python transcribe.py <録音フォルダ> [相手の人数]
pyannoteで話している区間を切り出し、区間ごとにwhisperにかける。
（無音の多い録音を丸ごとwhisperに渡すと、内容が縮んだり抜けたりするため）
"""
import sys
import wave
from pathlib import Path

import mlx_whisper
import numpy as np
import torch
from pyannote.audio import Pipeline

MODEL = "mlx-community/whisper-large-v3-turbo"
d = Path(sys.argv[1])
n_them = int(sys.argv[2]) if len(sys.argv) > 2 else None

pipe = Pipeline.from_pretrained("pyannote/speaker-diarization-community-1")
pipe.to(torch.device("mps"))


def load(path):
    with wave.open(str(path)) as w:
        assert w.getframerate() == 16000
        return np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768


def chunks(x, n):
    out = pipe({"waveform": torch.from_numpy(x)[None], "sample_rate": 16000},
               **({"num_speakers": n} if n else {}))
    ann = getattr(out, "speaker_diarization", out)
    merged = []
    for t, _, spk in ann.itertracks(yield_label=True):
        # 同じ話者の1秒未満の切れ目はつなぐ（30秒を超えない範囲で）
        if merged and merged[-1][2] == spk and t.start - merged[-1][1] < 1.0 and t.end - merged[-1][0] < 30:
            merged[-1][1] = t.end
        else:
            merged.append([t.start, t.end, spk])
    return merged


def transcribe(name, n, label):
    x = load(d / f"{name}.wav")
    for s, e, spk in chunks(x, n):
        if e - s < 0.5:  # 短すぎる区間はwhisperが幻聴（「ご視聴ありがとうございました」等）を出す
            continue
        segs = mlx_whisper.transcribe(x[int(s * 16000):int(e * 16000)], path_or_hf_repo=MODEL,
                                      language="ja")["segments"]
        # 自信の低い部分（雑音から出た意味のない文字列）は捨てる。
        # no_speech_prob はこのモデルだと無音でも0なので使えない
        text = "".join(g["text"] for g in segs if g["avg_logprob"] > -1.0).strip()
        if text:
            yield s, label(spk), text


lines = list(transcribe("me", 1, lambda spk: "自分"))
lines += transcribe("them", n_them, (lambda spk: "相手") if n_them == 1 else (lambda spk: spk))

out = d / "transcript.txt"
out.write_text("".join(f"[{int(t)//60:02d}:{int(t)%60:02d}] {who}: {text}\n" for t, who, text in sorted(lines)))
print(out)
