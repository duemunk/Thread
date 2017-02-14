//
//  Thread.swift
//  Thread
//
//  This code is based on the following StackOverflow answer: http://stackoverflow.com/a/22091859
//  Permission to redristribute has been granted by the original author (Marc Haisenko).
//
//  Created by Tobias Due Munk on 27/11/15.
//  Copyright (c) 2015 Tobias Due Munk. All rights reserved.
//


import Foundation

/// FIFO. First-In-First-Out guaranteed on exactly same thread.
class Thread: Foundation.Thread {
    
    typealias Block = () -> ()

    private let condition = NSCondition()
    private(set) var queue = [Block]()
    private(set) var paused: Bool = false

    /**
     Designated initializer.
     - parameters:
        - start: Boolean whether thread should start immediately. Defaults to true.
        - queue: Initial array of blocks to add to enqueue. Executed in order of objects in array.
    */
    init(start: Bool = true, queue: [Block]? = nil) {
        super.init()
        // Add blocks initially to queue
        if let queue = queue {
            for block in queue {
                enqueue(block)
            }
        }
        // Start thread
        if start {
            self.start()
        }
    }

    /**
     The main entry point routine for the thread.
     You should never invoke this method directly. You should always start your thread by invoking the start method.
     Shouldn't invoke `super`.
     */
    final override func main() {

        // Infinite loops until thread is cancelled
        while true {
            // Use NSCondition. Comments are from Apple documentation on NSCondition
            // 1. Lock the condition object.
            condition.lock()

            // 2. Test a boolean predicate. (This predicate is a boolean flag or other variable in your code that indicates whether it is safe to perform the task protected by the condition.)
            // If no blocks (or paused) and not cancelled
            while (queue.count == 0 || paused) && !isCancelled  {
                // 3. If the boolean predicate is false, call the condition object’s wait or waitUntilDate: method to block the thread. Upon returning from these methods, go to step 2 to retest your boolean predicate. (Continue waiting and retesting the predicate until it is true.)
                condition.wait()
            }
            // 4. If the boolean predicate is true, perform the task.

            // If your thread supports cancellation, it should check this property periodically and exit if it ever returns true.
            if (isCancelled) {
                condition.unlock()
                return
            }

            // As per http://stackoverflow.com/a/22091859 by Marc Haisenko:
            // Execute block outside the condition, since it's also a lock!
            // We want to give other threads the possibility to enqueue
            // a new block while we're executing a block.
            let block = queue.removeFirst()
            condition.unlock()
            // Run block
            block()
        }
    }

    /**
     Add a block to be run on the thread. FIFO.
     - parameters:
        - block: The code to run.
     */
    final func enqueue(_ block: @escaping Block) {
        // Lock to ensure first-in gets added to array first
        condition.lock()
        // Add to queue
        queue.append(block)
        // Release from .wait()
        condition.signal()
        // Release lock
        condition.unlock()
    }

    /**
     Start the thread.
     - Warning: Don't start thread again after it has been cancelled/stopped.
     - SeeAlso: .start()
     - SeeAlso: .pause()
     */
    final override func start() {
        // Lock to let all mutations to behaviour obey FIFO
        condition.lock()
        // Unpause. Might be in pause state
        // Start
        super.start()
        // Release from .wait()
        condition.signal()
        // Release lock
        condition.unlock()
    }

    /**
     Cancels the thread.
     - Warning: Don't start thread again after it has been cancelled/stopped. Use .pause() instead.
     - SeeAlso: .start()
     - SeeAlso: .pause()
     */
    final override func cancel() {
        // Lock to let all mutations to behaviour obey FIFO
        condition.lock()
        // Cancel NSThread
        super.cancel()
        // Release from .wait()
        condition.signal()
        // Release lock
        condition.unlock()
    }

    /**
     Pause the thread. To completely stop it (i.e. remove it from the run-time), use `.cancel()`
     - Warning: Thread is still runnin,
     - SeeAlso: .start()
     - SeeAlso: .cancel()
     */
    final func pause() {
        // Lock to let all mutations to behaviour obey FIFO
        condition.lock()
        //
        paused = true
        // Release from .wait()
        condition.signal()
        // Release lock
        condition.unlock()
    }

    /**
     Resume the execution of blocks from the queue on the thread.
     - Warning: Can't resume if thread was cancelled/stopped.
     - SeeAlso: .start()
     - SeeAlso: .cancel()
     */
    final func resume() {
        // Lock to let all mutations to behaviour obey FIFO
        condition.lock()
        //
        paused = false
        // Release from .wait()
        condition.signal()
        // Release lock
        condition.unlock()
    }

    /**
     Empty the queue for any blocks that hasn't been run yet
     - SeeAlso:
        - .enqueue(block: Block)
        - .cancel()
     */
    final func emptyQueue() {
        // Lock to let all mutations to behaviour obey FIFO
        condition.lock()
        // Remove any blocks from the queue
        queue.removeAll()
        // Release from .wait()
        condition.signal()
        // Release lock
        condition.unlock()
    }
}
