window.FaceWeb = {
    modelsLoaded: false,
    stream: null,
    videoEl: null,
    registeredDescriptor: null,

    initModels: async function() {
        if (this.modelsLoaded) return;
        console.log("Loading face-api models...");
        const modelPath = './models';
        await faceapi.nets.tinyFaceDetector.loadFromUri(modelPath);
        await faceapi.nets.faceLandmark68Net.loadFromUri(modelPath);
        await faceapi.nets.faceRecognitionNet.loadFromUri(modelPath);
        this.modelsLoaded = true;
        console.log("Models loaded successfully.");
    },

    startCamera: async function(videoElementId) {
        this.videoEl = document.getElementById(videoElementId);
        if (!this.videoEl) throw new Error("Video element not found");
        
        const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
        this.videoEl.srcObject = stream;
        this.stream = stream;
        
        return new Promise((resolve) => {
            this.videoEl.onloadedmetadata = () => {
                this.videoEl.play();
                resolve();
            };
        });
    },

    stopCamera: function() {
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
            this.stream = null;
        }
    },

    _base64ToImage: function(base64) {
        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => resolve(img);
            img.onerror = reject;
            if (!base64.startsWith('data:image')) {
                img.src = 'data:image/jpeg;base64,' + base64;
            } else {
                img.src = base64;
            }
        });
    },

    captureForRegistration: async function() {
        if (!this.videoEl) return JSON.stringify({ error: "Kamera belum siap." });
        
        try {
            const detection = await faceapi.detectSingleFace(this.videoEl, new faceapi.TinyFaceDetectorOptions()).withFaceLandmarks().withFaceDescriptor();
            
            if (!detection) {
                return JSON.stringify({ error: "Tidak ada wajah terdeteksi. Pastikan wajah terlihat jelas di kamera." });
            }

            let targetWidth = this.videoEl.videoWidth;
            let targetHeight = this.videoEl.videoHeight;
            if (targetWidth > 400) {
                targetHeight = Math.round(targetHeight * (400 / targetWidth));
                targetWidth = 400;
            }

            const canvas = document.createElement('canvas');
            canvas.width = targetWidth;
            canvas.height = targetHeight;
            canvas.getContext('2d').drawImage(this.videoEl, 0, 0, targetWidth, targetHeight);
            
            // Mirror it back for saving
            const flipCanvas = document.createElement('canvas');
            flipCanvas.width = canvas.width;
            flipCanvas.height = canvas.height;
            const fctx = flipCanvas.getContext('2d');
            fctx.translate(flipCanvas.width, 0);
            fctx.scale(-1, 1);
            fctx.drawImage(canvas, 0, 0);

            const base64 = flipCanvas.toDataURL('image/jpeg', 0.6).split(',')[1];
            
            return JSON.stringify({ base64: base64 });
        } catch (e) {
            return JSON.stringify({ error: e.toString() });
        }
    },

    prepareRegisteredFace: async function(base64) {
        try {
            const img = await this._base64ToImage(base64);
            const detection = await faceapi.detectSingleFace(img, new faceapi.TinyFaceDetectorOptions()).withFaceLandmarks().withFaceDescriptor();
            if (detection) {
                this.registeredDescriptor = detection.descriptor;
                return true;
            }
            return false;
        } catch (e) {
            console.error(e);
            return false;
        }
    },

    captureAndVerify: async function() {
        if (!this.videoEl) return JSON.stringify({ error: "Kamera belum siap." });
        if (!this.registeredDescriptor) return JSON.stringify({ error: "Data wajah terdaftar tidak valid atau gagal dimuat." });

        try {
            const detection = await faceapi.detectSingleFace(this.videoEl, new faceapi.TinyFaceDetectorOptions()).withFaceLandmarks().withFaceDescriptor();
            
            if (!detection) {
                return JSON.stringify({ error: "Mendeteksi wajah..." }); // Use a soft error so Dart can poll again
            }

            const distance = faceapi.euclideanDistance(detection.descriptor, this.registeredDescriptor);
            
            let targetWidth = this.videoEl.videoWidth;
            let targetHeight = this.videoEl.videoHeight;
            if (targetWidth > 400) {
                targetHeight = Math.round(targetHeight * (400 / targetWidth));
                targetWidth = 400;
            }

            const canvas = document.createElement('canvas');
            canvas.width = targetWidth;
            canvas.height = targetHeight;
            canvas.getContext('2d').drawImage(this.videoEl, 0, 0, targetWidth, targetHeight);
            const base64 = canvas.toDataURL('image/jpeg', 0.6).split(',')[1];

            // face-api strictness
            if (distance <= 0.55) {
                return JSON.stringify({ match: true, base64: base64, distance: distance });
            } else {
                return JSON.stringify({ match: false, error: "Wajah tidak cocok. Tolong dekatkan atau atur pencahayaan.", distance: distance });
            }
        } catch (e) {
            return JSON.stringify({ error: e.toString() });
        }
    }
};
