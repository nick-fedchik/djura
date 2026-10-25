// diagnostics.js — Клієнтська діагностика для Geek Jack на Xbox Series X / Web
(function() {
    console.log("🛠️ Geek Jack Client Diagnostics Initialized");

    const diag = {
        fps: 60,
        frame_time_ms: 16.6,
        gpu: "Detecting...",
        screen: `${window.innerWidth}x${window.innerHeight} (DPR: ${window.devicePixelRatio || 1})`,
        gamepad: { count: 0, name: "none" },
        errors: [],
        ua: navigator.userAgent
    };

    // 1. GPU Detection
    try {
        const c = document.createElement("canvas");
        const gl = c.getContext("webgl2") || c.getContext("webgl");
        if (gl) {
            const ext = gl.getExtension("WEBGL_debug_renderer_info");
            diag.gpu = ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
        }
    } catch(e) {
        diag.gpu = "WebGL query error: " + e.message;
    }

    // 2. Error Catching
    window.addEventListener("error", (e) => {
        diag.errors.push(`${e.message} at ${e.filename}:${e.lineno}`);
    });
    window.addEventListener("unhandledrejection", (e) => {
        diag.errors.push(`Unhandled rejection: ${e.reason}`);
    });

    // 3. Gamepad Monitoring
    function checkGamepad() {
        const gpList = navigator.getGamepads ? navigator.getGamepads() : [];
        let activeGp = null;
        let count = 0;
        for (let i = 0; i < gpList.length; i++) {
            if (gpList[i]) {
                count++;
                if (!activeGp) activeGp = gpList[i];
            }
        }
        diag.gamepad.count = count;
        diag.gamepad.name = activeGp ? activeGp.id : "none";
        
        // Show/hide Xbox virtual mouse hint
        const hintEl = document.getElementById("xbox-gamepad-hint");
        const isXbox = navigator.userAgent.includes("Xbox");
        if (hintEl) {
            if (count === 0 && isXbox) {
                hintEl.style.display = "block";
            } else {
                hintEl.style.display = "none";
            }
        }
    }

    // 4. FPS Meter
    let lastTime = performance.now();
    let frames = 0;
    let accumulatedTime = 0;

    function measureFPS(now) {
        const delta = now - lastTime;
        lastTime = now;
        frames++;
        accumulatedTime += delta;

        if (accumulatedTime >= 1000) {
            diag.fps = Math.round((frames * 1000) / accumulatedTime * 10) / 10;
            diag.frame_time_ms = Math.round(accumulatedTime / frames * 10) / 10;
            frames = 0;
            accumulatedTime = 0;
            updateHud();
        }
        requestAnimationFrame(measureFPS);
    }
    requestAnimationFrame(measureFPS);

    // 5. On-Screen HUD & Virtual Mouse Hint
    function setupDOM() {
        // Mini HUD
        const hud = document.createElement("div");
        hud.id = "geek-jack-hud";
        hud.style.cssText = "position:fixed;top:8px;left:8px;background:rgba(0,0,0,0.75);color:#8ef;font-family:monospace;font-size:12px;padding:4px 8px;border-radius:4px;z-index:999999;pointer-events:none;border:1px solid #48a;";
        hud.innerText = "Ініціалізація...";
        document.body.appendChild(hud);

        // Hint for Xbox Edge Virtual Mouse
        const hint = document.createElement("div");
        hint.id = "xbox-gamepad-hint";
        hint.style.cssText = "display:none;position:fixed;bottom:24px;left:50%;transform:translateX(-50%);background:rgba(180,20,20,0.92);color:#fff;font-family:sans-serif;font-size:16px;font-weight:bold;padding:12px 24px;border-radius:8px;z-index:999999;box-shadow:0 4px 16px rgba(0,0,0,0.8);border:2px solid #ffd700;text-align:center;";
        hint.innerHTML = "🎮 <b>УВАГА:</b> Натисніть кнопку <b>Menu (☰ три рисочки)</b> на геймпаді Xbox,<br>щоб перемкнути браузер у режим прямого керування грою!";
        document.body.appendChild(hint);
    }

    function updateHud() {
        const hud = document.getElementById("geek-jack-hud");
        if (hud) {
            hud.innerText = `FPS: ${diag.fps} (${diag.frame_time_ms}ms) | GP: ${diag.gamepad.count} | Res: ${window.innerWidth}x${window.innerHeight}`;
            if (diag.fps < 40) {
                hud.style.color = "#ff6";
            } else {
                hud.style.color = "#8ef";
            }
        }
    }

    // 6. Send Diagnostics to Server every 2.5s
    async function sendTelemetry() {
        checkGamepad();
        diag.screen = `${window.innerWidth}x${window.innerHeight} (DPR: ${window.devicePixelRatio || 1})`;
        try {
            await fetch("/api/diagnostics", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(diag)
            });
        } catch(e) {
            // Ignore fetch network errors
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", () => {
            setupDOM();
            setInterval(sendTelemetry, 2500);
        });
    } else {
        setupDOM();
        setInterval(sendTelemetry, 2500);
    }
})();
