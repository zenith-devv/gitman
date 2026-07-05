import std/[httpclient, uri, json, strformat, strutils, terminal]

proc search*(query: string): (string, string, bool) =
    if query.len == 0:
        styledEcho styleBright, fgRed, "Error: Please specify a search query."
        quit(1)
        
    var url: string
    var isDirectRepo = false
    let client = newHttpClient()
    defer: client.close()
    client.headers = newHttpHeaders({"User-Agent": "gitman"})
    
    if query.contains("://"):
        let path = parseUri(query).path 
        let parts = path.split('/')        
        var repoName = parts[^1]
        if repoName == "" and parts.len > 1:
            repoName = parts[^2]
        return (query, repoName, true)
    elif query.contains('/'):
        let parts = query.split('/')
        let user = parts[0]
        let repo = parts[1]    
        url = "https://api.github.com/repos/" & user & "/" & repo
        isDirectRepo = true
    else:
        url = &"https://api.github.com/search/repositories?q={query}"

    styledEcho styleBright, fgCyan, &"Searching for '{query}'...\n"

    try:
        let response = client.getContent(url)
        let jsonNode = parseJson(response)
        
        var repoData: JsonNode

        if isDirectRepo:
            repoData = jsonNode
        else:
            let totalCount = jsonNode["total_count"].getInt()
            if totalCount == 0:
                styledEcho styleBright, fgRed, &"'{query}' was not found"
                quit(1)
            repoData = jsonNode["items"][0]

        let repoName = repoData["name"].getStr().toLowerAscii
        let repoFullName = repoData["full_name"].getStr()
        let description = if repoData["description"].kind == JNull: "No description provided." else: repoData["description"].getStr()
        let repoUrl = repoData["html_url"].getStr()
        let stargazersCount = repoData["stargazers_count"].getInt()

        styledEcho styleBright, fgCyan, "Full name     ", fgWhite, &"{repoFullName}"
        styledEcho styleBright, fgCyan, "Description   ", fgWhite, &"{description}"
        styledEcho styleBright, fgCyan, "URL           ", fgWhite, &"{repoUrl}"
        styledEcho styleBright, fgCyan, "Stars         ", fgWhite, &"{stargazersCount}\n"

        return (repoUrl, repoName, false)
        
    except Exception as e:
        if query.contains('/') and "404" in e.msg:
            styledEcho styleBright, fgRed, &"'{query}' was not found"
        else:
            styledEcho styleBright, fgRed, "Error: ", resetStyle, e.msg
        quit(1)