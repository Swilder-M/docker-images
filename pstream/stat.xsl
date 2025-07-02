<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
    <html>
    <head>
        <title>RTMP Statistics Dashboard</title>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <script src="https://cdn.tailwindcss.com/3.4.16"></script>
    </head>
    <body class="bg-gray-50">
        <nav class="bg-white border-b border-indigo-100 shadow-sm">
            <div class="container mx-auto px-4 py-3 max-w-6xl flex justify-between items-center">
                <a class="font-bold text-lg flex items-center text-indigo-700" href="#">
                    <svg class="h-6 w-6 mr-2 text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                    <span class="hidden sm:inline">RTMP Statistics Dashboard</span>
                </a>
                <div class="flex items-center space-x-3">
                    <a href="https://github.com/Swilder-M/docker-images/tree/master/pstream" target="_blank" class="flex items-center text-indigo-700 px-3 py-1 rounded text-sm transition duration-200 hover:text-indigo-900">
                        <svg class="h-5 w-5 text-indigo-700" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.237 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                        </svg>
                        <span class="hidden sm:inline ml-1">GitHub</span>
                    </a>
                </div>
            </div>
        </nav>

        <div class="container mx-auto p-4 max-w-6xl">
            <!-- Server Overview -->
            <div class="bg-white rounded-lg shadow-md mb-6 overflow-hidden">
                <div class="bg-indigo-600 text-white px-4 py-2 font-bold flex items-center">
                    <svg class="h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01" />
                    </svg>
                    Server Overview
                </div>
                <div class="p-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                        <div class="border border-indigo-400 rounded-lg p-4 text-center shadow-sm hover:shadow-md transition duration-200">
                            <div class="flex items-center justify-center mb-2">
                                <svg class="h-5 w-5 text-indigo-600 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                <h5 class="font-bold text-gray-700">Server Uptime</h5>
                            </div>
                            <p class="text-indigo-600 font-bold mt-2">
                                <xsl:call-template name="format-time">
                                    <xsl:with-param name="seconds" select="/rtmp/uptime"/>
                                </xsl:call-template>
                            </p>
                        </div>
                        <div class="border border-indigo-400 rounded-lg p-4 text-center shadow-sm hover:shadow-md transition duration-200">
                            <div class="flex items-center justify-center mb-2">
                                <svg class="h-5 w-5 text-indigo-600 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                                </svg>
                                <h5 class="font-bold text-gray-700">Total Accepted</h5>
                            </div>
                            <p class="text-indigo-600 font-bold mt-2"><xsl:value-of select="/rtmp/naccepted"/></p>
                        </div>
                        <div class="border border-indigo-400 rounded-lg p-4 text-center shadow-sm hover:shadow-md transition duration-200">
                            <div class="flex items-center justify-center mb-2">
                                <svg class="h-5 w-5 text-indigo-600 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
                                </svg>
                                <h5 class="font-bold text-gray-700">Bandwidth In</h5>
                            </div>
                            <p class="text-indigo-600 font-bold mt-2">
                                <xsl:call-template name="format-bytes">
                                    <xsl:with-param name="bytes" select="/rtmp/bw_in"/>
                                </xsl:call-template>/s
                            </p>
                        </div>
                        <div class="border border-indigo-400 rounded-lg p-4 text-center shadow-sm hover:shadow-md transition duration-200">
                            <div class="flex items-center justify-center mb-2">
                                <svg class="h-5 w-5 text-indigo-600 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
                                </svg>
                                <h5 class="font-bold text-gray-700">Bandwidth Out</h5>
                            </div>
                            <p class="text-indigo-600 font-bold mt-2">
                                <xsl:call-template name="format-bytes">
                                    <xsl:with-param name="bytes" select="/rtmp/bw_out"/>
                                </xsl:call-template>/s
                            </p>
                        </div>
                    </div>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="bg-indigo-50 p-4 rounded-lg shadow-sm">
                            <h3 class="text-sm uppercase text-indigo-700 font-semibold mb-2 flex items-center">
                                <svg class="h-4 w-4 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                Server Information
                            </h3>
                            <p class="leading-relaxed">
                                <span class="font-semibold inline-block w-24">Version:</span> <span class="text-indigo-600 tracking-wide">nginx <xsl:value-of select="/rtmp/nginx_version"/> with nginx-rtmp-module <xsl:value-of select="/rtmp/nginx_rtmp_version"/></span><br/>
                                <span class="font-semibold inline-block w-24">Compiler:</span> <span class="text-indigo-600 tracking-wide"><xsl:value-of select="/rtmp/compiler"/></span><br/>
                                <span class="font-semibold inline-block w-24">Built:</span> <span class="text-indigo-600 tracking-wide"><xsl:value-of select="/rtmp/built"/></span>
                            </p>
                        </div>
                        <div class="bg-indigo-50 p-4 rounded-lg shadow-sm">
                            <h3 class="text-sm uppercase text-indigo-700 font-semibold mb-2 flex items-center">
                                <svg class="h-4 w-4 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
                                </svg>
                                Transfer Statistics
                            </h3>
                            <p class="leading-relaxed">
                                <span class="font-semibold inline-block w-36">Total Bytes In:</span> <span class="text-indigo-600 tracking-wide">
                                    <xsl:call-template name="format-bytes">
                                        <xsl:with-param name="bytes" select="/rtmp/bytes_in"/>
                                    </xsl:call-template>
                                </span><br/>
                                <span class="font-semibold inline-block w-36">Total Bytes Out:</span> <span class="text-indigo-600 tracking-wide">
                                    <xsl:call-template name="format-bytes">
                                        <xsl:with-param name="bytes" select="/rtmp/bytes_out"/>
                                    </xsl:call-template>
                                </span>
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Applications -->
            <xsl:for-each select="/rtmp/server/application">
                <div class="bg-white rounded-lg shadow-md mb-6 overflow-hidden">
                    <div class="bg-indigo-600 text-white px-4 py-2 flex justify-between items-center">
                        <span class="flex items-center">
                            <svg class="h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 4v16M17 4v16M3 8h4m10 0h4M3 12h18M3 16h4m10 0h4M4 20h16a1 1 0 001-1V5a1 1 0 00-1-1H4a1 1 0 00-1 1v14a1 1 0 001 1z" />
                            </svg>
                            Application: <xsl:value-of select="name"/>
                        </span>
                        <span class="bg-indigo-500 text-white px-2 py-1 rounded flex items-center">
                            <svg class="h-4 w-4 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                            </svg>
                            <xsl:value-of select="live/nclients"/> clients
                        </span>
                    </div>
                    <div>
                        <!-- Live Streams -->
                        <xsl:if test="count(live/stream) > 0">
                            <div class="overflow-x-auto">
                                <table class="w-full">
                                    <thead class="bg-indigo-100">
                                        <tr>
                                            <th class="px-4 py-2 text-left text-indigo-800">Stream Name</th>
                                            <th class="px-4 py-2 text-left text-indigo-800">Type</th>
                                            <th class="px-4 py-2 text-left text-indigo-800">Clients</th>
                                            <th class="px-4 py-2 text-left text-indigo-800">Time</th>
                                            <th class="px-4 py-2 text-left text-indigo-800">Bitrate</th>
                                            <th class="px-4 py-2 text-left text-indigo-800">Resolution</th>
                                            <th class="px-4 py-2 text-left text-indigo-800">Frame Rate</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each select="live/stream">
                                            <tr class="hover:bg-indigo-50 border-t">
                                                <td class="px-4 py-2 font-bold text-indigo-700"><xsl:value-of select="name"/></td>
                                                <td class="px-4 py-2">
                                                    <span class="bg-green-500 text-white px-2 py-1 rounded text-xs flex items-center inline-flex">
                                                        <svg class="h-3 w-3 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.636 18.364a9 9 0 010-12.728m12.728 0a9 9 0 010 12.728m-9.9-2.829a5 5 0 010-7.07m7.072 0a5 5 0 010 7.07M13 12a1 1 0 11-2 0 1 1 0 012 0z" />
                                                        </svg>
                                                        Live
                                                    </span>
                                                </td>
                                                <td class="px-4 py-2"><xsl:value-of select="nclients"/></td>
                                                <td class="px-4 py-2">
                                                    <xsl:call-template name="format-time">
                                                        <xsl:with-param name="seconds" select="time"/>
                                                    </xsl:call-template>
                                                </td>
                                                <td class="px-4 py-2">
                                                    <xsl:if test="bw_in">
                                                        <xsl:call-template name="format-bytes">
                                                            <xsl:with-param name="bytes" select="bw_in"/>
                                                        </xsl:call-template>/s
                                                    </xsl:if>
                                                </td>
                                                <td class="px-4 py-2">
                                                    <xsl:if test="meta/video/width">
                                                        <xsl:value-of select="meta/video/width"/>x<xsl:value-of select="meta/video/height"/>
                                                    </xsl:if>
                                                </td>
                                                <td class="px-4 py-2">
                                                    <xsl:if test="meta/video/frame_rate">
                                                        <xsl:value-of select="meta/video/frame_rate"/> fps
                                                    </xsl:if>
                                                </td>
                                            </tr>
                                            
                                            <!-- Clients for this stream -->
                                            <xsl:if test="count(client) > 0">
                                                <tr>
                                                    <td colspan="7" class="p-0">
                                                        <div class="bg-indigo-50 p-3">
                                                            <h6 class="mb-2 font-bold flex items-center text-indigo-700">
                                                                <svg class="h-4 w-4 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                                                                </svg>
                                                                Connected Clients:
                                                            </h6>
                                                            <div class="overflow-x-auto">
                                                                <table class="w-full border rounded-lg overflow-hidden">
                                                                    <thead class="bg-indigo-100">
                                                                        <tr>
                                                                            <th class="px-3 py-2 text-left text-sm text-indigo-800">ID</th>
                                                                            <th class="px-3 py-2 text-left text-sm text-indigo-800">Address</th>
                                                                            <th class="px-3 py-2 text-left text-sm text-indigo-800">Time</th>
                                                                            <th class="px-3 py-2 text-left text-sm text-indigo-800">Flash Version</th>
                                                                            <th class="px-3 py-2 text-left text-sm text-indigo-800">Page URL</th>
                                                                            <th class="px-3 py-2 text-left text-sm text-indigo-800">Type</th>
                                                                        </tr>
                                                                    </thead>
                                                                    <tbody>
                                                                        <xsl:for-each select="client">
                                                                            <tr class="border-t hover:bg-indigo-50">
                                                                                <td class="px-3 py-2 text-sm"><xsl:value-of select="id"/></td>
                                                                                <td class="px-3 py-2 text-sm"><xsl:value-of select="address"/></td>
                                                                                <td class="px-3 py-2 text-sm">
                                                                                    <xsl:call-template name="format-time">
                                                                                        <xsl:with-param name="seconds" select="time"/>
                                                                                    </xsl:call-template>
                                                                                </td>
                                                                                <td class="px-3 py-2 text-sm"><xsl:value-of select="flash_version"/></td>
                                                                                <td class="px-3 py-2 text-sm"><xsl:value-of select="pageurl"/></td>
                                                                                <td class="px-3 py-2 text-sm">
                                                                                    <xsl:choose>
                                                                                        <xsl:when test="publishing">
                                                                                            <span class="bg-red-500 text-white px-2 py-1 rounded text-xs flex items-center inline-flex">
                                                                                                <svg class="h-3 w-3 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                                                                                </svg>
                                                                                                Publishing
                                                                                            </span>
                                                                                        </xsl:when>
                                                                                        <xsl:otherwise>
                                                                                            <span class="bg-indigo-500 text-white px-2 py-1 rounded text-xs flex items-center inline-flex">
                                                                                                <svg class="h-3 w-3 mr-1" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
                                                                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                                                                                </svg>
                                                                                                Playing
                                                                                            </span>
                                                                                        </xsl:otherwise>
                                                                                    </xsl:choose>
                                                                                </td>
                                                                            </tr>
                                                                        </xsl:for-each>
                                                                    </tbody>
                                                                </table>
                                                            </div>
                                                        </div>
                                                    </td>
                                                </tr>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </tbody>
                                </table>
                            </div>
                        </xsl:if>
                        <xsl:if test="count(live/stream) = 0">
                            <div class="p-6 text-center text-gray-500 bg-indigo-50">
                                <svg class="h-12 w-12 mx-auto text-indigo-300 mb-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4m12 2l-4 4m0 0l-4-4m4 4V4" />
                                </svg>
                                <p class="text-lg font-medium">No active streams</p>
                                <p class="text-sm mt-1">Start a stream to see its statistics here</p>
                            </div>
                        </xsl:if>
                    </div>
                </div>
            </xsl:for-each>
            
            <div class="text-center mt-4 text-gray-500 text-sm p-4">
                Powered by nginx-rtmp-module • Page auto-refreshes every 30 seconds
            </div>
        </div>
        
        <script>
            // Auto-refresh the page every 30 seconds
            setTimeout(function() {
                window.location.reload();
            }, 30000);
        </script>
    </body>
    </html>
</xsl:template>

<!-- Helper template to format bytes -->
<xsl:template name="format-bytes">
    <xsl:param name="bytes"/>
    <xsl:choose>
        <xsl:when test="$bytes &gt;= 1099511627776">
            <xsl:value-of select="format-number($bytes div 1099511627776, '###,###.##')"/> TB
        </xsl:when>
        <xsl:when test="$bytes &gt;= 1073741824">
            <xsl:value-of select="format-number($bytes div 1073741824, '###,###.##')"/> GB
        </xsl:when>
        <xsl:when test="$bytes &gt;= 1048576">
            <xsl:value-of select="format-number($bytes div 1048576, '###,###.##')"/> MB
        </xsl:when>
        <xsl:when test="$bytes &gt;= 1024">
            <xsl:value-of select="format-number($bytes div 1024, '###,###.##')"/> KB
        </xsl:when>
        <xsl:when test="$bytes &gt; 0">
            <xsl:value-of select="$bytes"/> B
        </xsl:when>
        <xsl:otherwise>
            0 B
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Helper template to format time -->
<xsl:template name="format-time">
    <xsl:param name="seconds"/>
    <xsl:variable name="days" select="floor($seconds div 86400)"/>
    <xsl:variable name="hours" select="floor(($seconds mod 86400) div 3600)"/>
    <xsl:variable name="minutes" select="floor(($seconds mod 3600) div 60)"/>
    <xsl:variable name="secs" select="$seconds mod 60"/>
    
    <xsl:if test="$days &gt; 0">
        <xsl:value-of select="$days"/>d
    </xsl:if>
    <xsl:if test="$hours &gt; 0">
        <xsl:if test="$days &gt; 0"><xsl:text> </xsl:text></xsl:if>
        <xsl:value-of select="$hours"/>h
    </xsl:if>
    <xsl:if test="$minutes &gt; 0">
        <xsl:if test="$days &gt; 0 or $hours &gt; 0"><xsl:text> </xsl:text></xsl:if>
        <xsl:value-of select="$minutes"/>m
    </xsl:if>
    <xsl:if test="$days = 0">
        <xsl:if test="$hours &gt; 0 or $minutes &gt; 0"><xsl:text> </xsl:text></xsl:if>
        <xsl:value-of select="$secs"/>s
    </xsl:if>
</xsl:template>

</xsl:stylesheet>