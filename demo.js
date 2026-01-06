/**
 * Demo UI Controller for SharkLeakFinderKit
 * Handles UI interactions and leak simulations
 */

// Constants
const MAX_CHART_POINTS = 50;

// Initialize the leak finder
const leakFinder = new SharkLeakFinder();

// Scenario definitions
const scenarios = {
    eventListener: {
        name: 'Event Listener Leak',
        description: 'This scenario demonstrates memory leaks caused by event listeners that are never removed. Each iteration creates a new DOM element with an event listener but never removes it, causing the elements and their handlers to remain in memory.',
        simulate: function(rate) {
            const elements = [];
            const handler = () => console.log('Click handler');
            
            const element = document.createElement('div');
            element.className = 'leaked-element';
            element.addEventListener('click', handler);
            elements.push(element);
            
            leakFinder.recordLeak('eventListener', 
                'Event listener attached without removal', 
                1024);
        }
    },
    closure: {
        name: 'Closure Leak',
        description: 'Closures can inadvertently hold references to large objects, preventing garbage collection. This scenario creates closures that capture large data arrays, demonstrating how memory can accumulate.',
        simulate: function(rate) {
            const largeData = new Array(10000).fill('data');
            
            // Closure captures largeData
            const closure = () => {
                return largeData[0];
            };
            
            // Store closure reference (simulating leak)
            window.__leakedClosures = window.__leakedClosures || [];
            window.__leakedClosures.push(closure);
            
            leakFinder.recordLeak('closure', 
                'Closure retaining large data array', 
                10000 * 8);
        }
    },
    detachedDOM: {
        name: 'Detached DOM Nodes',
        description: 'DOM nodes that are removed from the document but still referenced in JavaScript cannot be garbage collected. This scenario creates and removes DOM elements while maintaining references to them.',
        simulate: function(rate) {
            const div = document.createElement('div');
            div.innerHTML = '<p>Content</p>'.repeat(100);
            document.body.appendChild(div);
            
            // Remove from DOM but keep reference
            document.body.removeChild(div);
            
            // Store reference (simulating leak)
            window.__detachedNodes = window.__detachedNodes || [];
            window.__detachedNodes.push(div);
            
            leakFinder.recordLeak('detachedDOM', 
                'Detached DOM node with reference', 
                5000);
        }
    },
    timer: {
        name: 'Timer Leak',
        description: 'Intervals and timeouts that are never cleared continue to execute and hold references. This scenario creates timers that accumulate without being cleaned up.',
        simulate: function(rate) {
            let counter = 0;
            const timer = setInterval(() => {
                counter++;
            }, 1000);
            
            // Store timer reference but never clear
            window.__leakedTimers = window.__leakedTimers || [];
            window.__leakedTimers.push(timer);
            
            leakFinder.recordLeak('timer', 
                'Interval not cleared', 
                512);
        }
    },
    globalVar: {
        name: 'Global Variable Accumulation',
        description: 'Global variables persist for the lifetime of the application. This scenario demonstrates how continuously adding data to global scope can cause memory accumulation.',
        simulate: function(rate) {
            window.__globalCache = window.__globalCache || [];
            const largeObject = {
                data: new Array(5000).fill('cached data'),
                timestamp: Date.now()
            };
            window.__globalCache.push(largeObject);
            
            leakFinder.recordLeak('globalVar', 
                'Global variable accumulation', 
                5000 * 8);
        }
    }
};

// State management
let simulationInterval = null;
let currentScenario = null;
let chartData = {
    labels: [],
    values: []
};

// Helper function to clear leaked timers
function clearLeakedTimers() {
    if (window.__leakedTimers) {
        window.__leakedTimers.forEach(timer => clearInterval(timer));
        window.__leakedTimers = [];
    }
}

// Chart drawing
function drawChart() {
    const canvas = document.getElementById('memory-chart');
    const ctx = canvas.getContext('2d');
    const width = canvas.width = canvas.offsetWidth;
    const height = canvas.height = canvas.offsetHeight;
    
    // Clear canvas
    ctx.clearRect(0, 0, width, height);
    
    if (chartData.values.length === 0) {
        ctx.fillStyle = '#6c757d';
        ctx.font = '16px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('No data yet - start a simulation', width / 2, height / 2);
        return;
    }
    
    // Draw axes
    ctx.strokeStyle = '#dee2e6';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(50, 20);
    ctx.lineTo(50, height - 30);
    ctx.lineTo(width - 20, height - 30);
    ctx.stroke();
    
    // Draw data
    const maxValue = Math.max(...chartData.values, 1);
    const xStep = (width - 70) / Math.max(chartData.values.length - 1, 1);
    const yScale = (height - 60) / maxValue;
    
    ctx.strokeStyle = '#1e88e5';
    ctx.lineWidth = 3;
    ctx.beginPath();
    
    chartData.values.forEach((value, index) => {
        const x = 50 + index * xStep;
        const y = height - 30 - value * yScale;
        
        if (index === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
    });
    
    ctx.stroke();
    
    // Draw points
    ctx.fillStyle = '#1e88e5';
    chartData.values.forEach((value, index) => {
        const x = 50 + index * xStep;
        const y = height - 30 - value * yScale;
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, Math.PI * 2);
        ctx.fill();
    });
    
    // Labels
    ctx.fillStyle = '#212529';
    ctx.font = '12px Arial';
    ctx.textAlign = 'center';
    ctx.fillText('Time →', width / 2, height - 5);
    
    ctx.save();
    ctx.translate(15, height / 2);
    ctx.rotate(-Math.PI / 2);
    ctx.fillText('Objects Created →', 0, 0);
    ctx.restore();
}

// Update UI elements
function updateUI() {
    const stats = leakFinder.getStats();
    
    document.getElementById('objects-created').textContent = stats.objectsCreated;
    document.getElementById('memory-usage').textContent = 
        (stats.estimatedMemory / 1024).toFixed(2) + ' KB';
    document.getElementById('current-rate').textContent = 
        document.getElementById('leak-rate').value + '/sec';
    
    const statusEl = document.getElementById('status');
    if (simulationInterval) {
        statusEl.textContent = 'Running';
        statusEl.className = 'stat-value status-running pulsing';
    } else if (stats.objectsCreated > 0) {
        statusEl.textContent = 'Stopped';
        statusEl.className = 'stat-value status-idle';
    } else {
        statusEl.textContent = 'Idle';
        statusEl.className = 'stat-value status-idle';
    }
    
    // Update example output
    const output = `SharkLeakFinder Status:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scenario: ${currentScenario ? scenarios[currentScenario].name : 'None'}
Objects Created: ${stats.objectsCreated}
Leaked Objects: ${stats.leakedObjectsCount}
Estimated Memory: ${(stats.estimatedMemory / 1024).toFixed(2)} KB
Duration: ${stats.duration.toFixed(1)}s
Status: ${simulationInterval ? '🟢 Running' : '🔴 Stopped'}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`;
    
    document.getElementById('example-output').textContent = output;
}

// Event listeners
document.getElementById('scenario-select').addEventListener('change', (e) => {
    const scenarioId = e.target.value;
    const infoEl = document.getElementById('scenario-info');
    
    if (scenarioId && scenarios[scenarioId]) {
        const scenario = scenarios[scenarioId];
        infoEl.innerHTML = `
            <h3>${scenario.name}</h3>
            <p>${scenario.description}</p>
        `;
    } else {
        infoEl.innerHTML = '<p>Select a scenario above to see details about the memory leak pattern.</p>';
    }
});

document.getElementById('leak-rate').addEventListener('input', (e) => {
    document.getElementById('leak-rate-value').textContent = e.target.value;
    updateUI();
});

document.getElementById('start-btn').addEventListener('click', () => {
    const scenarioId = document.getElementById('scenario-select').value;
    
    if (!scenarioId) {
        alert('Please select a scenario first');
        return;
    }
    
    if (simulationInterval) {
        return;
    }
    
    currentScenario = scenarioId;
    const rate = parseInt(document.getElementById('leak-rate').value);
    const scenario = scenarios[scenarioId];
    
    // Start monitoring
    leakFinder.startMonitoring();
    
    // Start simulation
    simulationInterval = setInterval(() => {
        scenario.simulate(rate);
        
        // Update chart data
        chartData.labels.push(Date.now());
        chartData.values.push(leakFinder.getStats().objectsCreated);
        
        // Keep only last MAX_CHART_POINTS data points
        if (chartData.values.length > MAX_CHART_POINTS) {
            chartData.labels.shift();
            chartData.values.shift();
        }
        
        drawChart();
        updateUI();
    }, 1000 / rate);
    
    document.getElementById('start-btn').disabled = true;
    document.getElementById('stop-btn').disabled = false;
    document.getElementById('scenario-select').disabled = true;
    
    updateUI();
});

document.getElementById('stop-btn').addEventListener('click', () => {
    if (simulationInterval) {
        clearInterval(simulationInterval);
        simulationInterval = null;
        clearLeakedTimers();
    }
    
    leakFinder.stopMonitoring();
    
    document.getElementById('start-btn').disabled = false;
    document.getElementById('stop-btn').disabled = true;
    document.getElementById('scenario-select').disabled = false;
    
    updateUI();
});

document.getElementById('analyze-btn').addEventListener('click', () => {
    const analysis = leakFinder.analyze();
    const resultsEl = document.getElementById('analysis-results');
    
    let html = '<div class="' + (analysis.hasLeak ? 'leak-detected' : 'no-leak') + '">';
    
    if (analysis.hasLeak) {
        html += `
            <h3>⚠️ Memory Leak Detected</h3>
            <p><strong>Severity:</strong> ${analysis.severity}</p>
            <p><strong>Objects Created:</strong> ${analysis.objectsCreated}</p>
            <p><strong>Leaked Objects:</strong> ${analysis.leakedObjectsCount}</p>
            <p><strong>Estimated Memory:</strong> ${analysis.estimatedMemoryMB} MB</p>
            <p><strong>Leak Rate:</strong> ${analysis.leakRate} objects/second</p>
            <p><strong>Duration:</strong> ${analysis.duration.toFixed(1)} seconds</p>
        `;
        
        if (analysis.recommendations.length > 0) {
            html += '<h4>Recommendations:</h4><ul>';
            analysis.recommendations.forEach(rec => {
                html += `<li>${rec}</li>`;
            });
            html += '</ul>';
        }
    } else {
        html += `
            <h3>✅ No Memory Leaks Detected</h3>
            <p>The current monitoring session has not detected any memory leaks.</p>
            <p><strong>Duration:</strong> ${analysis.duration.toFixed(1)} seconds</p>
        `;
    }
    
    html += '</div>';
    resultsEl.innerHTML = html;
});

document.getElementById('clear-btn').addEventListener('click', () => {
    if (simulationInterval) {
        clearInterval(simulationInterval);
        simulationInterval = null;
        
        // Clear leaked timers
        if (window.__leakedTimers) {
            window.__leakedTimers.forEach(timer => clearInterval(timer));
        }
    }
    
    // Clear all leaked objects
    window.__leakedClosures = [];
    window.__detachedNodes = [];
    window.__leakedTimers = [];
    window.__globalCache = [];
    
    leakFinder.clear();
    currentScenario = null;
    chartData = { labels: [], values: [] };
    
    document.getElementById('start-btn').disabled = false;
    document.getElementById('stop-btn').disabled = true;
    document.getElementById('scenario-select').disabled = false;
    document.getElementById('scenario-select').value = '';
    document.getElementById('scenario-info').innerHTML = 
        '<p>Select a scenario above to see details about the memory leak pattern.</p>';
    document.getElementById('analysis-results').innerHTML = 
        '<p>Click "Analyze Memory" to see leak detection results.</p>';
    
    drawChart();
    updateUI();
});

// Initialize UI
updateUI();
drawChart();
