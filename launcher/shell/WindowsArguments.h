// SPDX-License-Identifier: MIT
#pragma once

#include <string>
#include <string_view>

namespace CmderShell
{
    // Quote one argument for CommandLineToArgvW / the Microsoft C runtime.
    // Pass the resulting command line directly to CreateProcessW, never a shell.
    inline std::wstring QuoteArgument(std::wstring_view argument)
    {
        std::wstring result(1, L'"');
        size_t backslashes = 0;
        for (const wchar_t character : argument)
        {
            if (character == L'\\') { ++backslashes; continue; }
            result.append(character == L'"' ? backslashes * 2 + 1 : backslashes, L'\\');
            result += character;
            backslashes = 0;
        }
        result.append(backslashes * 2, L'\\');
        result += L'"';
        return result;
    }
}
