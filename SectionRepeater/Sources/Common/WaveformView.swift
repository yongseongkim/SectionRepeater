//
//  WaveformView.swift
//  SectionRepeater
//
//  Created by KimYongSeong on 2017. 6. 4..
//  Copyright © 2017년 yongseongkim. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate
import SwiftyImage

protocol WaveformViewDelegate {
    func waveformViewDidScroll(scrollView: UIScrollView, progress: Double)
    func waveformViewWillBeginDragging(scrollView: UIScrollView)
    func waveformViewDidEndDragging(_ scrollView: UIScrollView, decelerate: Bool)
    func waveformViewDidEndDecelerating(scrollView: UIScrollView)
}

class WaveformView: UIView {
    static let sampleWidth: CGFloat = 2.0
    static let gapBetweenSamples: CGFloat = 1.0
    static let samplesPerPixel: Int = 3000
    
    public var delegate: WaveformViewDelegate?
    fileprivate var url: URL?
    fileprivate let scrollView = UIScrollView(frame: .zero).then { (scrollView) in
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
    }
    fileprivate var progressView: UIView?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.bottom.equalTo(self)
            make.right.equalTo(self)
        }
        self.scrollView.delegate = self
    }
    
    public func loadWaveform(url: URL) {
        // clean
        self.url = url
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: self.bounds.width / 2, bottom: 0, right: self.bounds.width / 2)
        for subview in self.scrollView.subviews {
            subview.removeFromSuperview()
        }
        // add waveform
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            do {
                let samples = try self.loadSamples(url: url)
                let imageSize = CGSize(width: WaveformView.sampleWidth * CGFloat(samples.count) + WaveformView.gapBetweenSamples * CGFloat(samples.count - 1), height: self.bounds.height)
                if let image = self.graphImage(samples: samples, imageSize: imageSize, color: UIColor.gray220) {
                    DispatchQueue.main.async {
                        if self.url?.absoluteString != url.absoluteString {
                            return
                        }
                        let backgroundImageView = UIImageView(image: image)
                        backgroundImageView.backgroundColor = UIColor.clear
                        self.scrollView.addSubview(backgroundImageView)
                        backgroundImageView.snp.makeConstraints({ (make) in
                            make.top.equalTo(self.scrollView)
                            make.left.equalTo(self.scrollView)
                            make.bottom.equalTo(self.scrollView)
                            make.right.equalTo(self.scrollView)
                            make.width.equalTo(imageSize.width)
                            make.height.equalTo(imageSize.height)
                        })

                        let progressImageView = UIImageView(image: image.with(color: UIColor.greenery))
                        progressImageView.backgroundColor = UIColor.clear
                        
                        let progressView = UIView(frame: .zero)
                        progressView.backgroundColor = UIColor.clear
                        progressView.clipsToBounds = true
                        progressView.addSubview(progressImageView)
                        progressImageView.snp.makeConstraints({ (make) in
                            make.top.equalTo(progressView)
                            make.left.equalTo(progressView)
                            make.bottom.equalTo(progressView)
                            make.width.equalTo(imageSize.width)
                            make.height.equalTo(imageSize.height)
                        })
                        self.scrollView.addSubview(progressView)
                        progressView.snp.makeConstraints({ (make) in
                            make.top.equalTo(self.scrollView)
                            make.left.equalTo(self.scrollView)
                            make.bottom.equalTo(self.scrollView)
                            make.width.equalTo(0)
                            make.height.equalTo(imageSize.height)
                        })
                        self.progressView = progressView
                        self.scrollView.contentSize = imageSize
                    }
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    public func move(progress: Double) {
        self.scrollView.contentOffset = CGPoint(x: (CGFloat(progress) * self.scrollView.contentSize.width) - self.scrollView.contentInset.left, y: 0)
    }
    
    fileprivate func loadSamples(url: URL?) throws -> [Float] {
        guard let url = url else { return [Float]() }
        let file = try AVAudioFile(forReading: url)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: file.fileFormat.sampleRate,
                                   channels: file.fileFormat.channelCount,
                                   interleaved: false)
        let buf = AVAudioPCMBuffer(pcmFormat: format,
                                   frameCapacity: UInt32(file.length))
        try file.read(into: buf)
        let samples = Array(UnsafeBufferPointer(start: buf.floatChannelData?[0], count:Int(buf.frameLength)))
        let downSamplesResult = self.downSamples(samples)
        return downSamplesResult
    }
    
    // sound cloud 1.5초 그래프 한칸당
    fileprivate func downSamples(_ samples: [Float]) -> [Float] {
        var processingBuffer = [Float](repeating: 0.0, count: Int(samples.count))
        let samplesCount = vDSP_Length(samples.count)
        vDSP_vabs(samples, 1, &processingBuffer, 1, samplesCount);
        let filter = [Float](repeating: 1.0 / Float(WaveformView.samplesPerPixel),
                             count: Int(WaveformView.samplesPerPixel))
        let downSamplesCount = Int(samples.count / WaveformView.samplesPerPixel)
        var result = [Float](repeating:0.0,
                                      count:downSamplesCount)
        vDSP_desamp(processingBuffer,
                    vDSP_Stride(WaveformView.samplesPerPixel),
                    filter,
                    &result,
                    vDSP_Length(downSamplesCount),
                    vDSP_Length(WaveformView.samplesPerPixel))
        return result
    }
    
    fileprivate func graphImage(samples: [Float], imageSize: CGSize, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(imageSize);
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(WaveformView.sampleWidth)
        let centerY = imageSize.height / 2
        var x:CGFloat = 0
        for idx in 0..<samples.count {
            var sampleWidth: CGFloat = CGFloat(samples[idx]) * 100
            if (sampleWidth < 1) {
                sampleWidth = 1
            }
            context?.move(to: CGPoint(x: x, y: centerY - sampleWidth))
            context?.addLine(to: CGPoint(x: x, y: centerY + sampleWidth))
            context?.setStrokeColor(color.cgColor)
            context?.strokePath()
            x = x + WaveformView.sampleWidth + WaveformView.gapBetweenSamples
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension WaveformView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var progress: Double = 0
        if (self.scrollView.contentSize.width > 0) {
            progress = Double((scrollView.contentOffset.x + self.scrollView.contentInset.left) / self.scrollView.contentSize.width)
        }
        self.progressView?.snp.updateConstraints({ (make) in
            make.width.equalTo(scrollView.contentSize.width * CGFloat(progress))
        })
        self.scrollView.layoutIfNeeded()
        self.delegate?.waveformViewDidScroll(scrollView: scrollView, progress: progress)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegate?.waveformViewWillBeginDragging(scrollView: scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.delegate?.waveformViewDidEndDragging(scrollView, decelerate: decelerate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegate?.waveformViewDidEndDecelerating(scrollView: scrollView)
    }
}