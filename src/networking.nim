import std/[httpclient, json, strformat, strutils, terminal]

proc search*(query: string): (string, string) =
    if query.len == 0:
        styledEcho styleBright, fgRed, "Error: Please specify a search query."
        quit(1)
        
    let client = newHttpClient()
    defer: client.close()
    client.headers = newHttpHeaders({"User-Agent": "gitman"})
    let url = &"https://api.github.com/search/repositories?q={query}"
    styledEcho styleBright, fgCyan, &"Searching for '{query}'...\n"

    try:
        let response = client.getContent(url)
        let jsonNode = parseJson(response)
        let totalCount = jsonNode["total_count"].getInt()
        if totalCount == 0:
            styledEcho styleBright, fgRed, &"'{query}' was not found"
            quit(1)

        let firstItem = jsonNode["items"][0]
        let repoName = firstItem["name"].getStr.toLowerAscii
        let repoFullName = firstItem["full_name"].getStr()
        let description = if firstItem["description"].kind == JNull: "No description provided." else: firstItem["description"].getStr()
        let repoUrl = firstItem["html_url"].getStr()
        let stargazersCount = firstItem["stargazers_count"].getInt()

        styledEcho styleBright, fgCyan, "Full name     ", fgWhite, &"{repoFullName}"
        styledEcho styleBright, fgCyan, "Description   ", fgWhite, &"{description}"
        styledEcho styleBright, fgCyan, "URL           ", fgWhite, &"{repoUrl}"
        styledEcho styleBright, fgCyan, "Stars         ", fgWhite, &"{stargazersCount}\n"

        return (repoUrl, repoName)
    except Exception as e:
        styledEcho styleBright, fgRed, "Error: ", resetStyle, e.msg
        quit(1)