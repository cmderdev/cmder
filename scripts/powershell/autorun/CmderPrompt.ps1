# Define cmder prompt.
function prompt()
{
    Write-Host -ForegroundColor Green "$PWD "
    Write-Host -NoNewline -ForegroundColor DarkGray "λ"
    return " "
}
