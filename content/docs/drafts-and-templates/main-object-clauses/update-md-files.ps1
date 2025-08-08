$files = Get-ChildItem -Filter *.md | Sort-Object Name
$weight = 306

foreach ($file in $files) {
    $lines = Get-Content $file.FullName
    $newContent = @()
    $inFrontMatter = $false
    $inDescription = $false
    $descriptionLines = @()
    $titleLine = ""
    $contentStartIndex = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line.Trim() -eq "---") {
            $inFrontMatter = -not $inFrontMatter
            if (-not $inFrontMatter) {
                $contentStartIndex = $i + 1
                break
            }
            continue
        }

        if ($inFrontMatter) {
            if ($line.TrimStart().StartsWith("description: >-")) {
                $inDescription = $true
                continue
            }

            if ($inDescription) {
                if ($line.Trim().StartsWith("#") -or $line.Trim() -eq "") {
                    $inDescription = $false
                } else {
                    $descriptionLines += $line.Trim()
                }
            }
        }
    }

    # Find the title from the markdown content
    for ($j = $contentStartIndex; $j -lt $lines.Count; $j++) {
        if ($lines[$j].Trim().StartsWith("# ")) {
            $titleLine = $lines[$j].Trim().Substring(2).Trim()
            $contentStartIndex = $j + 1
            break
        }
    }

    # Prepare new front matter
    $newFrontMatter = @(
        "---",
        "title: `"$titleLine`"",
        "weight: $weight",
        "layout: docs",
        "---",
        ""
    )

    # Add description as heading
    if ($descriptionLines.Count -gt 0) {
        $descLine = "##### " + ($descriptionLines -join " ")
        $newFrontMatter += $descLine
        $newFrontMatter += ""
    }

    # Add the rest of the content (excluding original front matter and old title)
    $remainingContent = $lines[$contentStartIndex..($lines.Count - 1)] | Where-Object { $_ -notmatch '^# ' }

    # Combine and write back
    $final = $newFrontMatter + $remainingContent
    Set-Content $file.FullName -Value $final -Encoding UTF8

    $weight++
}
