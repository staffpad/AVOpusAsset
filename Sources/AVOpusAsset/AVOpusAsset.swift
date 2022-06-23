//
//  AVOpusAsset.swift
//  AVOpusAsset
//
//  Created by Evan Olcott on 6/20/22.
//

import AVFoundation
import Foundation
import Opus

public class AVOpusAsset: AVAsset
{
    public enum Error: Swift.Error
    {
        case opusError(Int32)
        case formatError
    }
    
    private let tempFileURL: URL
    
    public init(opusFileURL: URL) throws
    {
        let data = try Data(contentsOf: opusFileURL)
                
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        try data.withUnsafeBytes
        {
            var err: Int32 = 0
            let bytes = $0.baseAddress!.assumingMemoryBound(to: UInt8.self)

            guard let file = op_open_memory(bytes, data.count, &err) else { throw Error.opusError(err) }
            defer { op_free(file) }
            
            let channelCount = Int(op_channel_count(file, -1))
            let outputFile = try AVAudioFile(forWriting: outputURL,
                                         settings:
            [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: channelCount,
                AVLinearPCMBitDepthKey: 16
            ])

            guard
                let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: 48000,
                                           channels: UInt32(channelCount),
                                           interleaved: channelCount > 1),
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                                 frameCapacity: AVAudioFrameCount(5760 * channelCount))
            else { throw Error.formatError }
            
            while
                case let readFrames = Int(op_read_float(file,
                                                        pcmBuffer.floatChannelData![0],
                                                        Int32(pcmBuffer.frameCapacity),
                                                        nil)),
                readFrames > 0
            {
                pcmBuffer.frameLength = AVAudioFrameCount(readFrames)
                try outputFile.write(from: pcmBuffer)
            }
        }
        
        self.tempFileURL = outputURL
        super.init(url: outputURL)
    }
    
    deinit
    {
        try? FileManager.default.removeItem(at: self.tempFileURL)
    }
}
