# Script to render slides from Markdown files
# This script is intended to be executed by a GitHub Actions workflow
# All the slides end up in the dist directory in a folder with the same name as the slide directory

# If the script is executed from the .github/workflows directory, change to the root directory of the repository
$rootDirectory = Get-Location
$pathSeparator = [IO.Path]::DirectorySeparatorChar
if ($rootDirectory.Path -match "\.github${pathSeparator}workflows$") {
    Set-Location -Path "..${pathSeparator}.."
    $rootDirectory = Get-Location
}

# Create the dist directory if it doesn't exist
$distDirectory = Join-Path -Path $rootDirectory.Path -ChildPath 'dist'
if (-not (Test-Path -Path $distDirectory)) {
    New-Item -Path $distDirectory -ItemType Directory
    # copy all files from the site-root folder to the dist folder
    Copy-Item -Path "site-root${pathSeparator}*" -Destination $distDirectory -Recurse -Force
}

# Load all the slide direcotries
$slideDirectories = Get-ChildItem -Path . -Directory | Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}' } | Select-Object -ExpandProperty Name
$totalSlides = $slideDirectories.Count
$currentSlide = 0

foreach ($slideDirectory in $slideDirectories) {
    $currentSlide++
    Write-Progress -Activity "Rendering slides" -Status "Processing $slideDirectory ($currentSlide of $totalSlides)" -PercentComplete (($currentSlide / $totalSlides) * 100)

    $slideDirectoryPath = Join-Path -Path $rootDirectory.Path -ChildPath $slideDirectory
    $slideDirectoryPath

    $slideFiles = Get-ChildItem -Path $slideDirectoryPath -Filter 'index.md' | Select-Object -ExpandProperty FullName

    # If there is no index.md file, skip the directory
    if ($slideFiles.Count -eq 0) {
        continue
    }

    # Create the slide directory in the dist directory
    $slideDistDirectory = Join-Path -Path $distDirectory -ChildPath $slideDirectory
    if (-not (Test-Path -Path $slideDistDirectory)) {
        New-Item -Path $slideDistDirectory -ItemType Directory
    }

    foreach ($slideFile in $slideFiles) {
        #"Rendering $slideFile using Marp CLI"
        #$slideFile
        # Call `npx @marp-team/marp-cli@latest $slideFile --output $slideDistDirectory/index.html`
        Start-Process -FilePath 'npx' -ArgumentList '@marp-team/marp-cli@latest', $slideFile, '--output', "${slideDistDirectory}${pathSeparator}index.html", "--yes" -NoNewWindow -Wait
        #"Slide rendered"
    }

    # If it has a subfolder called assets, copy it to the dist directory
    $assetsDirectory = Join-Path -Path $slideDirectoryPath -ChildPath 'assets'
    if (Test-Path -Path $assetsDirectory) {
        Copy-Item -Path $assetsDirectory -Destination $slideDistDirectory -Recurse -Force
    }
}
Write-Progress -Activity "Rendering slides" -Status "Completed" -PercentComplete 100
Write-Progress -Completed -Activity "Rendering slides"

Write-Host "Listing files under the dist directory"
$distFiles = Get-ChildItem -Path $distDirectory -Recurse
foreach ($file in $distFiles) {
    Write-Host $file.FullName
}

Write-Host "Done rendering slides"