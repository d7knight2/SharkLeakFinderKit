/**
 * SharkLeakFinder - Memory Leak Detection Library
 * A lightweight JavaScript library for detecting and analyzing memory leaks
 */

class SharkLeakFinder {
    constructor() {
        this.isMonitoring = false;
        this.objectsCreated = 0;
        this.startTime = null;
        this.leakedObjects = [];
        this.memorySnapshots = [];
        this.currentScenario = null;
        this.monitoringInterval = null;
        this.maxSnapshots = 100;
    }

    /**
     * Start monitoring for memory leaks
     */
    startMonitoring() {
        if (this.isMonitoring) {
            console.warn('Monitoring is already active');
            return;
        }

        this.isMonitoring = true;
        this.startTime = Date.now();
        this.objectsCreated = 0;
        this.leakedObjects = [];
        this.memorySnapshots = [];

        console.log('SharkLeakFinder: Monitoring started');
    }

    /**
     * Stop monitoring
     */
    stopMonitoring() {
        if (!this.isMonitoring) {
            console.warn('Monitoring is not active');
            return;
        }

        this.isMonitoring = false;
        console.log('SharkLeakFinder: Monitoring stopped');
    }

    /**
     * Record a leaked object
     */
    recordLeak(type, description, estimatedSize = 1024) {
        if (!this.isMonitoring) return;

        const leak = {
            id: ++this.objectsCreated,
            type,
            description,
            estimatedSize,
            timestamp: Date.now(),
            stackTrace: this.captureStackTrace()
        };

        this.leakedObjects.push(leak);
        
        // Take memory snapshot
        this.takeSnapshot();
    }

    /**
     * Capture stack trace (simplified)
     */
    captureStackTrace() {
        try {
            throw new Error();
        } catch (e) {
            return e.stack || 'Stack trace not available';
        }
    }

    /**
     * Take a memory snapshot
     */
    takeSnapshot() {
        const snapshot = {
            timestamp: Date.now(),
            objectCount: this.objectsCreated,
            estimatedMemory: this.getEstimatedMemory(),
            leakCount: this.leakedObjects.length
        };

        this.memorySnapshots.push(snapshot);

        // Keep only last maxSnapshots snapshots
        if (this.memorySnapshots.length > this.maxSnapshots) {
            this.memorySnapshots.shift();
        }
    }

    /**
     * Get estimated memory usage
     */
    getEstimatedMemory() {
        return this.leakedObjects.reduce((total, leak) => {
            return total + leak.estimatedSize;
        }, 0);
    }

    /**
     * Analyze current state for memory leaks
     */
    analyze() {
        const duration = this.startTime ? (Date.now() - this.startTime) / 1000 : 0;
        const estimatedMemory = this.getEstimatedMemory();
        const leakRate = duration > 0 ? this.objectsCreated / duration : 0;

        const analysis = {
            duration,
            objectsCreated: this.objectsCreated,
            leakedObjectsCount: this.leakedObjects.length,
            estimatedMemory,
            estimatedMemoryMB: (estimatedMemory / (1024 * 1024)).toFixed(2),
            leakRate: leakRate.toFixed(2),
            hasLeak: this.leakedObjects.length > 0,
            severity: this.calculateSeverity(leakRate, estimatedMemory),
            recommendations: this.generateRecommendations(),
            snapshots: this.memorySnapshots
        };

        return analysis;
    }

    /**
     * Calculate leak severity
     */
    calculateSeverity(leakRate, memory) {
        const memoryMB = memory / (1024 * 1024);

        if (leakRate > 50 || memoryMB > 100) {
            return 'CRITICAL';
        } else if (leakRate > 20 || memoryMB > 50) {
            return 'HIGH';
        } else if (leakRate > 10 || memoryMB > 20) {
            return 'MEDIUM';
        } else if (leakRate > 0) {
            return 'LOW';
        }
        return 'NONE';
    }

    /**
     * Generate recommendations based on leak analysis
     */
    generateRecommendations() {
        const recommendations = [];
        const leakTypes = new Set(this.leakedObjects.map(l => l.type));

        if (leakTypes.has('eventListener')) {
            recommendations.push('Remove event listeners when elements are destroyed');
        }
        if (leakTypes.has('closure')) {
            recommendations.push('Avoid storing large objects in closures; use references carefully');
        }
        if (leakTypes.has('detachedDOM')) {
            recommendations.push('Set DOM element references to null after removing from document');
        }
        if (leakTypes.has('timer')) {
            recommendations.push('Always clear intervals and timeouts when no longer needed');
        }
        if (leakTypes.has('globalVar')) {
            recommendations.push('Minimize use of global variables; clean up when done');
        }

        if (recommendations.length === 0 && this.leakedObjects.length > 0) {
            recommendations.push('Review object lifecycle and ensure proper cleanup');
        }

        return recommendations;
    }

    /**
     * Clear all tracked leaks and reset
     */
    clear() {
        this.objectsCreated = 0;
        this.leakedObjects = [];
        this.memorySnapshots = [];
        this.currentScenario = null;
        this.startTime = null;
        console.log('SharkLeakFinder: Data cleared');
    }

    /**
     * Get memory usage statistics
     */
    getStats() {
        return {
            objectsCreated: this.objectsCreated,
            leakedObjectsCount: this.leakedObjects.length,
            estimatedMemory: this.getEstimatedMemory(),
            isMonitoring: this.isMonitoring,
            duration: this.startTime ? (Date.now() - this.startTime) / 1000 : 0
        };
    }
}

// Export for use in other scripts
if (typeof window !== 'undefined') {
    window.SharkLeakFinder = SharkLeakFinder;
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = SharkLeakFinder;
}
