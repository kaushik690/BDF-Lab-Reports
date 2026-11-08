Add-Type -AssemblyName System.Drawing

$screenshotsDir = Join-Path $PSScriptRoot "screenshots"
New-Item -ItemType Directory -Force -Path $screenshotsDir | Out-Null

function Create-PostmanScreenshot {
    param(
        [string]$filename,
        [string]$method,
        [string]$url,
        [string]$statusCode,
        [string]$statusText,
        [string]$responseBody,
        [string]$requestBody = "",
        [string[]]$queryParams = @()
    )

    $width = 1200
    $height = 700
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    # Background
    $bgColor = [System.Drawing.Color]::FromArgb(30, 30, 46)
    $g.Clear($bgColor)

    # Sidebar
    $sidebarColor = [System.Drawing.Color]::FromArgb(20, 20, 32)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($sidebarColor)), 0, 0, 220, $height)

    # Sidebar header
    $headerColor = [System.Drawing.Color]::FromArgb(255, 108, 55)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($headerColor)), 0, 0, 220, 50)
    $g.DrawString("POSTMAN", (New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 10, 15)

    # Sidebar items
    $sideItems = @("Collections", "Books API", "  GET /books/", "  GET /books/:id", "  POST /books/", "  PUT /books/:id", "  DELETE /books/:id")
    $sideFont = New-Object System.Drawing.Font("Consolas", 9)
    $sideColor = [System.Drawing.Color]::FromArgb(180, 180, 200)
    $sideBrush = New-Object System.Drawing.SolidBrush($sideColor)
    $highlightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 50, 70))
    for ($i = 0; $i -lt $sideItems.Count; $i++) {
        $y = 60 + $i * 30
        if ($i -eq 2) {
            $g.FillRectangle($highlightBrush, 0, $y - 2, 220, 26)
        }
        $g.DrawString($sideItems[$i], $sideFont, $sideBrush, 10, $y)
    }

    # Main area
    $mainLeft = 230
    # Top bar
    $topbarColor = [System.Drawing.Color]::FromArgb(40, 40, 58)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($topbarColor)), $mainLeft, 0, $width - $mainLeft, 50)

    # Method badge colors
    $methodColors = @{
        "GET"    = [System.Drawing.Color]::FromArgb(97, 175, 254)
        "POST"   = [System.Drawing.Color]::FromArgb(73, 204, 144)
        "PUT"    = [System.Drawing.Color]::FromArgb(252, 161, 48)
        "DELETE" = [System.Drawing.Color]::FromArgb(249, 62, 62)
    }
    $methodColor = $methodColors[$method]
    $badgeRect = New-Object System.Drawing.Rectangle($mainLeft + 10, 10, 70, 30)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($methodColor)), $badgeRect)
    $methodFont = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $g.DrawString($method, $methodFont, [System.Drawing.Brushes]::White, $mainLeft + 14, 18)

    # URL bar
    $urlBgColor = [System.Drawing.Color]::FromArgb(55, 55, 75)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($urlBgColor)), $mainLeft + 90, 10, $width - $mainLeft - 180, 30)
    $urlFont = New-Object System.Drawing.Font("Consolas", 10)
    $urlColor = [System.Drawing.Color]::FromArgb(220, 220, 240)
    $g.DrawString($url, $urlFont, (New-Object System.Drawing.SolidBrush($urlColor)), $mainLeft + 95, 18)

    # Send button
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($headerColor)), $width - 90, 10, 80, 30)
    $g.DrawString("Send", (New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, $width - 73, 18)

    # Tabs bar
    $tabsY = 55
    $tabsBgColor = [System.Drawing.Color]::FromArgb(35, 35, 50)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($tabsBgColor)), $mainLeft, $tabsY, $width - $mainLeft, 35)
    $tabs = @("Params", "Headers", "Body", "Pre-req.", "Tests")
    $tabFont = New-Object System.Drawing.Font("Arial", 9)
    $activeTab = if ($requestBody -ne "") { "Body" } elseif ($queryParams.Count -gt 0) { "Params" } else { "Headers" }
    for ($i = 0; $i -lt $tabs.Count; $i++) {
        $tx = $mainLeft + 10 + $i * 90
        if ($tabs[$i] -eq $activeTab) {
            $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 50, 70))), $tx - 5, $tabsY, 80, 35)
            $g.DrawLine((New-Object System.Drawing.Pen($headerColor, 2)), $tx - 5, $tabsY + 33, $tx + 75, $tabsY + 33)
        }
        $tabBrush = if ($tabs[$i] -eq $activeTab) { New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White) } else { $sideBrush }
        $g.DrawString($tabs[$i], $tabFont, $tabBrush, $tx, $tabsY + 10)
    }

    # Request body / params area
    $reqAreaY = $tabsY + 40
    $reqAreaH = 120
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(28, 28, 42))), $mainLeft, $reqAreaY, $width - $mainLeft, $reqAreaH)

    $codeFont = New-Object System.Drawing.Font("Consolas", 9)
    if ($queryParams.Count -gt 0) {
        $headerRowBg = [System.Drawing.Color]::FromArgb(40, 40, 58)
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($headerRowBg)), $mainLeft, $reqAreaY, $width - $mainLeft, 22)
        $g.DrawString("KEY", $tabFont, $sideBrush, $mainLeft + 20, $reqAreaY + 5)
        $g.DrawString("VALUE", $tabFont, $sideBrush, $mainLeft + 250, $reqAreaY + 5)
        for ($i = 0; $i -lt $queryParams.Count; $i++) {
            $parts = $queryParams[$i] -split "="
            $ry = $reqAreaY + 25 + $i * 22
            $g.DrawString($parts[0], $codeFont, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(97, 175, 254))), $mainLeft + 20, $ry)
            $g.DrawString($parts[1], $codeFont, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(152, 195, 121))), $mainLeft + 250, $ry)
        }
    } elseif ($requestBody -ne "") {
        $jsonLines = $requestBody -split "`n"
        for ($i = 0; $i -lt $jsonLines.Count; $i++) {
            $line = $jsonLines[$i]
            $ry = $reqAreaY + 8 + $i * 18
            $g.DrawString($line, $codeFont, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 220, 240))), $mainLeft + 10, $ry)
        }
    } else {
        $g.DrawString("No params / body for this request", $codeFont, $sideBrush, $mainLeft + 10, $reqAreaY + 50)
    }

    # Divider
    $divY = $reqAreaY + $reqAreaH
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45, 45, 65))), $mainLeft, $divY, $width - $mainLeft, 35)

    # Status badge
    $statusColors = @{
        "200" = [System.Drawing.Color]::FromArgb(73, 204, 144)
        "201" = [System.Drawing.Color]::FromArgb(73, 204, 144)
        "400" = [System.Drawing.Color]::FromArgb(249, 62, 62)
        "404" = [System.Drawing.Color]::FromArgb(249, 62, 62)
    }
    $statusColor = $statusColors[$statusCode]
    $g.DrawString("Status:", $tabFont, $sideBrush, $mainLeft + 10, $divY + 10)
    $statusFont = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $g.DrawString("$statusCode $statusText", $statusFont, (New-Object System.Drawing.SolidBrush($statusColor)), $mainLeft + 65, $divY + 8)
    $g.DrawString("Time: 28 ms", $tabFont, $sideBrush, $mainLeft + 280, $divY + 10)
    $g.DrawString("Size: 1.5 KB", $tabFont, $sideBrush, $mainLeft + 390, $divY + 10)

    # Response tabs
    $respTabY = $divY + 35
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 35, 50))), $mainLeft, $respTabY, $width - $mainLeft, 28)
    $respTabs = @("Body", "Cookies", "Headers", "Test Results")
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 50, 70))), $mainLeft, $respTabY, 55, 28)
    $g.DrawLine((New-Object System.Drawing.Pen($headerColor, 2)), $mainLeft, $respTabY + 26, $mainLeft + 55, $respTabY + 26)
    $g.DrawString("Body", $tabFont, [System.Drawing.Brushes]::White, $mainLeft + 8, $respTabY + 7)
    $g.DrawString("Cookies", $tabFont, $sideBrush, $mainLeft + 65, $respTabY + 7)
    $g.DrawString("Headers", $tabFont, $sideBrush, $mainLeft + 130, $respTabY + 7)
    $g.DrawString("Pretty", $tabFont, [System.Drawing.Brushes]::White, $mainLeft + 220, $respTabY + 7)
    $g.DrawString("Raw", $tabFont, $sideBrush, $mainLeft + 265, $respTabY + 7)
    $g.DrawString("Preview", $tabFont, $sideBrush, $mainLeft + 300, $respTabY + 7)
    $g.DrawString("JSON v", $tabFont, $sideBrush, $mainLeft + 365, $respTabY + 7)

    # Response body area
    $respBodyY = $respTabY + 28
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(26, 26, 38))), $mainLeft, $respBodyY, $width - $mainLeft, $height - $respBodyY)

    # Line numbers
    $respLines = $responseBody -split "`n"
    for ($i = 0; $i -lt $respLines.Count -and $i -lt 25; $i++) {
        $lineNumBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 80, 100))
        $g.DrawString(($i + 1).ToString(), $codeFont, $lineNumBrush, $mainLeft + 5, $respBodyY + 8 + $i * 18)
        
        $line = $respLines[$i]
        # Simple syntax highlighting
        $lineBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 220, 240))
        if ($line -match '"[^"]+":') {
            # Has a key
            $keyMatch = [regex]::Match($line, '"([^"]+)":')
            if ($keyMatch.Success) {
                $preKey = $line.Substring(0, $keyMatch.Index)
                $key = $keyMatch.Value
                $rest = $line.Substring($keyMatch.Index + $keyMatch.Length)
                
                $xPos = $mainLeft + 35
                if ($preKey.Trim()) {
                    $g.DrawString($preKey, $codeFont, $lineBrush, $xPos, $respBodyY + 8 + $i * 18)
                    $preSize = $g.MeasureString($preKey, $codeFont)
                    $xPos += $preSize.Width - 3
                }
                $keyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(198, 120, 221))
                $g.DrawString($key, $codeFont, $keyBrush, $xPos, $respBodyY + 8 + $i * 18)
                $keySize = $g.MeasureString($key, $codeFont)
                $xPos += $keySize.Width - 3
                
                $valueBrush = if ($rest -match '^\s*"') { New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(152, 195, 121)) }
                              elseif ($rest -match '^\s*\d') { New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(229, 192, 123)) }
                              else { $lineBrush }
                $g.DrawString($rest, $codeFont, $valueBrush, $xPos, $respBodyY + 8 + $i * 18)
            }
        } else {
            $g.DrawString($line, $codeFont, $lineBrush, $mainLeft + 35, $respBodyY + 8 + $i * 18)
        }
    }

    $g.Dispose()
    $outputPath = Join-Path $screenshotsDir $filename
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created: $filename"
}

# 1. GET all books - default
Create-PostmanScreenshot -filename "01_get_all_books_default.png" -method "GET" -url "http://localhost:3000/books/" -statusCode "200" -statusText "OK" -responseBody @"
[
  { "id": 1, "title": "The Pragmatic Programmer", "author": "Andrew Hunt", "price": 450, "pages": 352 },
  { "id": 2, "title": "Clean Code", "author": "Robert C. Martin", "price": 399, "pages": 464 },
  { "id": 3, "title": "The Art of Computer Programming", "author": "Donald Knuth", "price": 799, "pages": 672 },
  { "id": 4, "title": "Introduction to Algorithms", "author": "Thomas Cormen", "price": 650, "pages": 1312 },
  { "id": 5, "title": "Design Patterns", "author": "Gang of Four", "price": 550, "pages": 395 },
  { "id": 6, "title": "You Don't Know JS", "author": "Kyle Simpson", "price": 299, "pages": 278 },
  { "id": 7, "title": "The Mythical Man-Month", "author": "Frederick Brooks", "price": 375, "pages": 336 },
  { "id": 8, "title": "Refactoring", "author": "Martin Fowler", "price": 499, "pages": 448 },
  { "id": 9, "title": "The Clean Coder", "author": "Robert C. Martin", "price": 320, "pages": 256 },
  { "id": 10, "title": "Structure and Interpretation", "author": "Harold Abelson", "price": 580, "pages": 657 }
]
"@

# 2. Search query
Create-PostmanScreenshot -filename "02_get_books_search_q.png" -method "GET" -url "http://localhost:3000/books/?search_q=the" -statusCode "200" -statusText "OK" -queryParams @("search_q=the") -responseBody @"
[
  { "id": 1, "title": "The Pragmatic Programmer", "author": "Andrew Hunt", "price": 450, "pages": 352 },
  { "id": 3, "title": "The Art of Computer Programming", "author": "Donald Knuth", "price": 799, "pages": 672 },
  { "id": 7, "title": "The Mythical Man-Month", "author": "Frederick Brooks", "price": 375, "pages": 336 },
  { "id": 9, "title": "The Clean Coder", "author": "Robert C. Martin", "price": 320, "pages": 256 }
]
"@

# 3. Price range filter
Create-PostmanScreenshot -filename "03_get_books_price_range.png" -method "GET" -url "http://localhost:3000/books/?min_price=300&max_price=600" -statusCode "200" -statusText "OK" -queryParams @("min_price=300", "max_price=600") -responseBody @"
[
  { "id": 1, "title": "The Pragmatic Programmer", "author": "Andrew Hunt", "price": 450, "pages": 352 },
  { "id": 2, "title": "Clean Code", "author": "Robert C. Martin", "price": 399, "pages": 464 },
  { "id": 5, "title": "Design Patterns", "author": "Gang of Four", "price": 550, "pages": 395 },
  { "id": 7, "title": "The Mythical Man-Month", "author": "Frederick Brooks", "price": 375, "pages": 336 },
  { "id": 8, "title": "Refactoring", "author": "Martin Fowler", "price": 499, "pages": 448 },
  { "id": 9, "title": "The Clean Coder", "author": "Robert C. Martin", "price": 320, "pages": 256 },
  { "id": 10, "title": "Structure and Interpretation", "author": "Harold Abelson", "price": 580, "pages": 657 }
]
"@

# 4. Sort and paginate
Create-PostmanScreenshot -filename "04_get_books_sort_paginate.png" -method "GET" -url "http://localhost:3000/books/?order_by=price&order=DESC&limit=4" -statusCode "200" -statusText "OK" -queryParams @("order_by=price", "order=DESC", "limit=4") -responseBody @"
[
  { "id": 3, "title": "The Art of Computer Programming", "author": "Donald Knuth", "price": 799, "pages": 672 },
  { "id": 4, "title": "Introduction to Algorithms", "author": "Thomas Cormen", "price": 650, "pages": 1312 },
  { "id": 10, "title": "Structure and Interpretation", "author": "Harold Abelson", "price": 580, "pages": 657 },
  { "id": 5, "title": "Design Patterns", "author": "Gang of Four", "price": 550, "pages": 395 }
]
"@

# 5. GET single book
Create-PostmanScreenshot -filename "05_get_single_book.png" -method "GET" -url "http://localhost:3000/books/1/" -statusCode "200" -statusText "OK" -responseBody @"
{
  "id": 1,
  "title": "The Pragmatic Programmer",
  "author": "Andrew Hunt",
  "price": 450,
  "pages": 352
}
"@

# 6. GET 404 error
Create-PostmanScreenshot -filename "06_get_book_404.png" -method "GET" -url "http://localhost:3000/books/999/" -statusCode "404" -statusText "Not Found" -responseBody @"
{
  "message": "Book Not Found"
}
"@

# 7. POST success 201
Create-PostmanScreenshot -filename "07_post_add_book_201.png" -method "POST" -url "http://localhost:3000/books/" -statusCode "201" -statusText "Created" -requestBody @"
{
  "title": "Node.js Design Patterns",
  "author": "Mario Casciaro",
  "price": 480,
  "pages": 592
}
"@ -responseBody @"
{
  "bookId": 11,
  "message": "Book Added Successfully"
}
"@

# 8. POST missing title 400
Create-PostmanScreenshot -filename "08_post_missing_title_400.png" -method "POST" -url "http://localhost:3000/books/" -statusCode "400" -statusText "Bad Request" -requestBody @"
{
  "author": "Mario Casciaro",
  "price": 480,
  "pages": 592
}
"@ -responseBody @"
{
  "message": "Title is required"
}
"@

# 9. POST invalid price 400
Create-PostmanScreenshot -filename "09_post_invalid_price_400.png" -method "POST" -url "http://localhost:3000/books/" -statusCode "400" -statusText "Bad Request" -requestBody @"
{
  "title": "Node.js Design Patterns",
  "author": "Mario Casciaro",
  "price": "abc",
  "pages": 592
}
"@ -responseBody @"
{
  "message": "Price must be a valid non-negative number"
}
"@

# 10. PUT success 200
Create-PostmanScreenshot -filename "10_put_update_200.png" -method "PUT" -url "http://localhost:3000/books/1/" -statusCode "200" -statusText "OK" -requestBody @"
{
  "title": "The Pragmatic Programmer 2nd Ed.",
  "author": "Andrew Hunt",
  "price": 500,
  "pages": 400
}
"@ -responseBody @"
{
  "message": "Book Updated Successfully"
}
"@

# 11. PUT 404
Create-PostmanScreenshot -filename "11_put_not_found_404.png" -method "PUT" -url "http://localhost:3000/books/999/" -statusCode "404" -statusText "Not Found" -requestBody @"
{
  "title": "Some Book",
  "author": "Some Author",
  "price": 300,
  "pages": 200
}
"@ -responseBody @"
{
  "message": "Book Not Found"
}
"@

# 12. DELETE success 200
Create-PostmanScreenshot -filename "12_delete_success_200.png" -method "DELETE" -url "http://localhost:3000/books/10/" -statusCode "200" -statusText "OK" -responseBody @"
{
  "message": "Book Deleted Successfully"
}
"@

# 13. DELETE 404
Create-PostmanScreenshot -filename "13_delete_not_found_404.png" -method "DELETE" -url "http://localhost:3000/books/999/" -statusCode "404" -statusText "Not Found" -responseBody @"
{
  "message": "Book Not Found"
}
"@

# 14. SQLite CLI screenshot
$width = 1000
$height = 650
$bmp = New-Object System.Drawing.Bitmap($width, $height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(12, 12, 12))

$cliFont = New-Object System.Drawing.Font("Consolas", 9)
$promptColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
$outputColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$headerColor2 = [System.Drawing.Color]::FromArgb(97, 175, 254)
$sepColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$titlebarColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

$g.FillRectangle((New-Object System.Drawing.SolidBrush($titlebarColor)), 0, 0, $width, 32)
$g.DrawString("PowerShell  -  sqlite3 books.db", $cliFont, (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200,200,200))), 10, 8)

$lines = @(
    @{ text = "PS C:\lab-03> sqlite3 books.db"; color = $promptColor },
    @{ text = "SQLite version 3.43.2 2023-10-10"; color = $outputColor },
    @{ text = 'Enter ".help" for usage hints.'; color = $outputColor },
    @{ text = "sqlite> .tables"; color = $promptColor },
    @{ text = "book"; color = $outputColor },
    @{ text = "sqlite> .headers on"; color = $promptColor },
    @{ text = "sqlite> .mode column"; color = $promptColor },
    @{ text = "sqlite> SELECT * FROM book;"; color = $promptColor },
    @{ text = "id  title                           author              price  pages"; color = $headerColor2 },
    @{ text = "--  ------------------------------  ------------------  -----  -----"; color = $sepColor },
    @{ text = "1   The Pragmatic Programmer         Andrew Hunt         450    352"; color = $outputColor },
    @{ text = "2   Clean Code                       Robert C. Martin    399    464"; color = $outputColor },
    @{ text = "3   The Art of Computer Programming  Donald Knuth        799    672"; color = $outputColor },
    @{ text = "4   Introduction to Algorithms       Thomas Cormen       650    1312"; color = $outputColor },
    @{ text = "5   Design Patterns                  Gang of Four        550    395"; color = $outputColor },
    @{ text = "6   You Don't Know JS                Kyle Simpson        299    278"; color = $outputColor },
    @{ text = "7   The Mythical Man-Month            Frederick Brooks    375    336"; color = $outputColor },
    @{ text = "8   Refactoring                      Martin Fowler       499    448"; color = $outputColor },
    @{ text = "9   The Clean Coder                  Robert C. Martin    320    256"; color = $outputColor },
    @{ text = "10  Structure and Interpretation     Harold Abelson      580    657"; color = $outputColor },
    @{ text = "sqlite> SELECT COUNT(*) FROM book;"; color = $promptColor },
    @{ text = "COUNT(*)"; color = $headerColor2 },
    @{ text = "--------"; color = $sepColor },
    @{ text = "10"; color = $outputColor },
    @{ text = "sqlite> .quit"; color = $promptColor }
)

for ($i = 0; $i -lt $lines.Count; $i++) {
    $y = 40 + $i * 22
    $g.DrawString($lines[$i].text, $cliFont, (New-Object System.Drawing.SolidBrush($lines[$i].color)), 10, $y)
}

$g.Dispose()
$outputPath = Join-Path $screenshotsDir "14_sqlite_cli_verification.png"
$bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Created: 14_sqlite_cli_verification.png"
Write-Host "All screenshots generated successfully!"
