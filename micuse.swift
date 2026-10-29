// いまマイクを使っているアプリのバンドルIDを1行ずつ出す（macOS 14以降のCoreAudio API）
import CoreAudio

func addr(_ sel: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: sel, mScope: kAudioObjectPropertyScopeGlobal,
                               mElement: kAudioObjectPropertyElementMain)
}

var a = addr(kAudioHardwarePropertyProcessObjectList)
var size: UInt32 = 0
AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size)
var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size, &ids)

for id in ids {
    var running: UInt32 = 0
    var s = UInt32(MemoryLayout<UInt32>.size)
    var ra = addr(kAudioProcessPropertyIsRunningInput)
    guard AudioObjectGetPropertyData(id, &ra, 0, nil, &s, &running) == noErr, running != 0 else { continue }
    var bundle: CFString = "" as CFString
    var bs = UInt32(MemoryLayout<CFString>.size)
    var ba = addr(kAudioProcessPropertyBundleID)
    AudioObjectGetPropertyData(id, &ba, 0, nil, &bs, &bundle)
    print(bundle)
}
