$jsDir = "web\js"
$modelsDir = "web\models"

if (-not (Test-Path $jsDir)) { New-Item -ItemType Directory -Path $jsDir | Out-Null }
if (-not (Test-Path $modelsDir)) { New-Item -ItemType Directory -Path $modelsDir | Out-Null }

Write-Host "Downloading face-api.min.js..."
Invoke-WebRequest -Uri "https://cdn.jsdelivr.net/npm/face-api.js@0.22.2/dist/face-api.min.js" -OutFile "$jsDir\face-api.min.js"

$baseUrl = "https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/"
$files = @(
    "tiny_face_detector_model-weights_manifest.json",
    "tiny_face_detector_model-shard1",
    "face_landmark_68_model-weights_manifest.json",
    "face_landmark_68_model-shard1",
    "face_recognition_model-weights_manifest.json",
    "face_recognition_model-shard1",
    "face_recognition_model-shard2"
)

foreach ($file in $files) {
    Write-Host "Downloading $file..."
    Invoke-WebRequest -Uri "$baseUrl$file" -OutFile "$modelsDir\$file"
}

Write-Host "Download complete!"
