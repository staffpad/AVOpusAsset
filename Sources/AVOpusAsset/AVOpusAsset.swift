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
    
    public init(url: URL) throws
    {
        let data = try Data(contentsOf: url)
        
        // read opus file contents into AVAudioPCMBuffer
        
        let audioBuffer: AVAudioPCMBuffer = try data.withUnsafeBytes
        {
            var err: Int32 = 0
            let bytes = $0.baseAddress!.assumingMemoryBound(to: UInt8.self)

            guard let file = op_open_memory(bytes, data.count, &err) else { throw Error.opusError(err) }
            defer { op_free(file) }
            
            let channelCount = Int(op_channel_count(file, -1))
            let total = Int(op_pcm_total(file, -1))
            
            guard
                let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                           sampleRate: 48000,
                                           channels: UInt32(channelCount),
                                           interleaved: channelCount > 1),
                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                                 frameCapacity: AVAudioFrameCount(total))
            else { throw Error.formatError }
            
            let framesToRead = Int32(960 * channelCount)
            var writeCursor: Int = 0

            while
                writeCursor < total,
                case let readFrames = Int(op_read_float(file,
                                                        pcmBuffer.floatChannelData![0].advanced(by: writeCursor),
                                                        framesToRead,
                                                        nil)),
                readFrames > 0
            {
                writeCursor += readFrames * channelCount
            }
            
            return pcmBuffer
        }
        
        // write AVAudioPCMBuffer to WAVE file in temp directory
        
        tempFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        let outputFile = try AVAudioFile(forWriting: tempFileURL,
                                     settings:
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16
        ])

        try outputFile.write(from: audioBuffer)
        
        // init asset with temp URL
        
        super.init(url: tempFileURL)
    }
    
    deinit
    {
        try? FileManager.default.removeItem(at: tempFileURL)
    }
}
