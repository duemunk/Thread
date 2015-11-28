//
//  ThreadTests.swift
//  ThreadTests
//
//  Created by Tobias Due Munk on 27/11/15.
//  Copyright © 2015 developmunk. All rights reserved.
//

import XCTest
#if os(iOS)
    @testable import ThreadiOS
#elseif os(tvOS)
    @testable import ThreadtvOS
#elseif os(OSX)
    @testable import ThreadOSX
#endif

class ThreadTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEnqueueSingle() {
        let expectation = expectationWithDescription("First")

        let thread = Thread()
        thread.enqueue {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testEnqueueMultiple() {
        let expectation1 = expectationWithDescription("First")
        let expectation2 = expectationWithDescription("Second")

        let thread = Thread()
        var visitedFirst = false
        thread.enqueue {
            expectation1.fulfill()
            visitedFirst = true
        }
        thread.enqueue {
            expectation2.fulfill()
            XCTAssert(visitedFirst, "Didn't run first before this secondary block")
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCancel() {
        let expectation1 = expectationWithDescription("First")
        let expectationWait = expectationWithDescription("Wait")

        let thread = Thread()
        thread.enqueue {
            thread.cancel()
            expectation1.fulfill()
        }
        thread.enqueue {
            XCTFail("This block is enqueued after first block, so shouldn't be run")
        }

        asyncAfter(0.1) {
            expectationWait.fulfill()
        }

        // Wait
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testEmptyQueue() {
        let expectation1 = expectationWithDescription("First")
        let expectationWait = expectationWithDescription("Wait")

        let thread = Thread()
        thread.enqueue {
            expectation1.fulfill()
            NSThread.sleepForTimeInterval(0.1)
        }
        thread.enqueue {
            XCTFail("This block is enqueued after first block, so shouldn't be run")
        }
        dispatch_async(dispatch_get_main_queue()) {
            XCTAssertEqual(thread.queue.count, 1)
            thread.emptyQueue()
            XCTAssertEqual(thread.queue.count, 0)
        }

        asyncAfter(0.2) {
            expectationWait.fulfill()
        }

        // Wait
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testPause() {
        let expectation1 = expectationWithDescription("First")
        let expectation2 = expectationWithDescription("Second")
        let expectationWait = expectationWithDescription("Wait")

        let thread = Thread()
        var paused: Bool = false
        var resumed: Bool = false
        thread.enqueue {
            paused = true
            thread.pause()
            XCTAssert(thread.paused, "Should be in paused state")
            expectation1.fulfill()
        }
        thread.enqueue {
            XCTAssert(paused, "Should have been stopped once")
            XCTAssert(resumed, "Should have been restarted again")
            expectation2.fulfill()
        }

        asyncAfter(0.1) {
            expectationWait.fulfill()
            resumed = true
            thread.resume()
            XCTAssertFalse(thread.paused, "Shouldn't be in paused state")
        }

        // Wait
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}


extension ThreadTests {

    private func asyncAfter(seconds: Double, queue: dispatch_queue_t = dispatch_get_main_queue(), block: dispatch_block_t) {
        let nanoSeconds = Int64(seconds * Double(NSEC_PER_SEC))
        let time = dispatch_time(DISPATCH_TIME_NOW, nanoSeconds)
        at(time, block: block, queue: queue)
    }
    private func at(time: dispatch_time_t, block: dispatch_block_t, queue: dispatch_queue_t) {
        // See Async.async() for comments
        dispatch_after(time, queue, block)
    }
}
