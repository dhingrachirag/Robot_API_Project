*** Settings ***
Library    RequestsLibrary
Library    Zoomba.APILibrary
Library    ../Customlibs/ExtendedHTTPLibrary.py
Library    ../Customlibs/Geolocation.py
Variables  ../APITests.py
Resource   ../Variables/globalvariables.robot
Resource   ../Variables/UFT_variables.robot
Library    JSONLibrary
Library    Collections
Library    String

*** Variables ***


*** Keywords ***
Get Available Tests UFT
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    folder=/Customers/Automation_US/Automation_us_api/ATT_Jasper
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=${host}    Connection=${keep-alive}    Content-Type=${accept}    Accept-Encoding=${enconding}    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${available_tests}    headers=${headers}    json=${demo_body}
    log    ${response}
    Should Be True     ${response.status_code} == 200
    ${available_tests}    get value from json     ${response.json()}    $.availableTests
    log    ${available_tests}

Login into UFT
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${UFT_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    folder=/Customers/Automation_US/Automation_us_api/ATT_Jasper
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}
    ${response}=    ExtendedHTTPLibrary.GET On Session    Automation    /siteapi    headers=${headers}
    log    ${response}
    Should Be True     ${response.status_code} == 200

Schedule WBR Test in UFT
    [Arguments]    ${customer}    ${country}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    ${tag_1}  Create Dictionary    name=a_location    value=${country}
    @{parameters}=    Create List    ${tag_1}
    &{body}  Create Dictionary
    ...    testDefinitionPath=${testcases_path}/${customer}/Enterprise
    ...    testDefinitionParameters=@{parameters}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${schedule}    headers=${headers}    json=${demo_body}
    log    ${response}    level=TRACE
    Should Be True     ${response.status_code} == 200
    ${order_ID}    get value from json     ${response.json()}    $.orderDetails.orderId
    log    ${order_ID}
    ${convertListToString}=   Evaluate             "".join(${order_ID})
    log    ${convertListToString}
    [Return]    ${convertListToString}

Run WBR test and check status
    [Arguments]    ${client}    ${country}
    sleep    30s
    ${order_ID}=    Schedule WBR Test in UFT    ${client}    ${country}
    log    ${order_ID}
    sleep    20s
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    orderId=${order_ID}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
             ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${test_status_UFT}    headers=${headers}    json=${demo_body}
             log    ${response}    level=TRACE
             sleep    30s
             ${verdict}    get value from json     ${response.json()}    $.testcaseStatusList[0].verdict
             log    ${verdict}
             ${status}    get value from json     ${response.json()}    $.testcaseStatusList[0].status
             log    ${status}
             ${status_Info}    get value from json     ${response.json()}    $.testcaseStatusList[0].statusInfo
             log    ${status_Info}
             ${status_check}=   Evaluate             "".join(${status})
             log    ${status_check}
             ${var}=    set variable if    '${status_check}' == '${done}' or '${status_check}' == '${aborted}'     ${verdict}
             exit for loop if    '${status_check}' == '${aborted}' or '${status_check}' == '${done}'
    END
    ${convertListToString}=   Evaluate             "".join(${var})
    log    ${convertListToString}
    ${convertListToString1}=   Evaluate             "".join(${status_Info})
    log    ${convertListToString1}
    IF    $location in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then change the location in UFT test case
    ELSE IF    $pdpcontext in $convertListToString1
        Fail    log    Need to rerun test one or two times.If same issue appeared multiple times then please check UFT test case configuration.
    ELSE IF    $webbrowsing in $convertListToString1
        Fail    log    This is either UFT issue or configuration issue. Rerun the test case one more time if same issue comes then please check the configuration.
    ELSE IF    $timeout in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then please check the configuration.
    ELSE
        Log    Either test case passed or any new error observed. please check Status Info.
    END
    should be equal    ${convertListToString}    ${passed_state}

Schedule Geolocation Test in UFT
    [Arguments]    ${customer}    ${country}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    ${tag_1}  Create Dictionary    name=a_location    value=${country}
    @{parameters}=    Create List    ${tag_1}
    &{body}  Create Dictionary
    ...    testDefinitionPath=${testcases_path}/${customer}/Geolocation
    ...    testDefinitionParameters=@{parameters}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${schedule}    headers=${headers}    json=${demo_body}
    log    ${response}    level=TRACE
    Should Be True     ${response.status_code} == 200
    ${order_ID}    get value from json     ${response.json()}    $.orderDetails.orderId
    log    ${order_ID}
    ${convertListToString}=   Evaluate             "".join(${order_ID})
    log    ${convertListToString}
    [Return]    ${convertListToString}

Run Geolocation test and check status
    [Arguments]    ${client}    ${country}
    sleep    30s
    ${order_ID}=    Schedule Geolocation Test in UFT    ${client}    ${country}
    log    ${order_ID}
    sleep    20s
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    orderId=${order_ID}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
             ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${test_status_UFT}    headers=${headers}    json=${demo_body}
             log    ${response}    level=TRACE
             sleep    30s
             ${verdict}    get value from json     ${response.json()}    $.testcaseStatusList[0].verdict
             log    ${verdict}
             ${status}    get value from json     ${response.json()}    $.testcaseStatusList[0].status
             log    ${status}
             ${status_Info}    get value from json     ${response.json()}    $.testcaseStatusList[0].statusInfo
             log    ${status_Info}
             ${test_UFT_id}    get value from json     ${response.json()}    $.testcaseStatusList[0].testcaseId
             log    ${test_UFT_id}
             ${status_check}=   Evaluate             "".join(${status})
             log    ${status_check}
             ${var}=    set variable if    '${status_check}' == '${done}' or '${status_check}' == '${aborted}'     ${verdict}
             exit for loop if    '${status_check}' == '${aborted}' or '${status_check}' == '${done}'
    END
    ${convertListToString}=   Evaluate             "".join(${var})
    log    ${convertListToString}
    ${convertListToString1}=   Evaluate             "".join(${status_Info})
    log    ${convertListToString1}
    ${testcase_id}=   Evaluate             "".join(${test_UFT_id})
    log    ${testcase_id}
    IF    $location in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then change the location in UFT test case
    ELSE IF    $pdpcontext in $convertListToString1
        Fail    log    Need to rerun test one or two times.If same issue appeared multiple times then please check UFT test case configuration.
    ELSE IF    $webbrowsing in $convertListToString1
        Fail    log    This is either UFT issue or configuration issue. Rerun the test case one more time if same issue comes then please check the configuration.
    ELSE IF    $timeout in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then please check the configuration.
    ELSE
        Log    Either test case passed or any new error observed. please check Status Info.
    END
    should be equal    ${convertListToString}    ${passed_state}
    [Return]    ${testcase_id}

Run Geolocation Test And Verify Exact Location for Specific APN
    [Arguments]    ${client}    ${country}    ${Geolocation}    ${test_country}
    sleep    30s
    ${test_id}=    Run Geolocation test and check status    ${client}    ${test_country}
    log    ${test_id}
    sleep    20s
    Set Log Level    Trace
    &{body}  Create Dictionary
    ...    testcaseId=${test_id}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    User-Agent=${user_agent}
    Download tracelogs    url_global=${global_roamer_url}/${resultfiles}   pkcs12_filename_roamer=${pkcs_directory}    pkcs12_password_roamer=${password_UFT}    destination_path_roamer=${dest_path_logs_us}/${Geolocation}    id_roam=${body}
    sleep    20s
    log    ${EXECDIR}
    Remove files    ${EXECDIR}/${Geolocation}/*.sh    ${EXECDIR}/${Geolocation}/*.csv    ${EXECDIR}/${Geolocation}/*.zip    ${EXECDIR}/${Geolocation}/*.log    ${EXECDIR}/${Geolocation}/*.har    ${EXECDIR}/${Geolocation}/*.pcap
    sleep    10s
    ${status}=    Run keyword and return status    Move file    ${EXECDIR}/${Geolocation}/*.html    ${EXECDIR}/${Geolocation}/Test_Geolocation.html
    sleep    5s
    Skip if    ${status} == ${False}    msg=Test case passed but intemittent API issue encountered while verifying the location.
    ${contents}=    get file    ${EXECDIR}/${Geolocation}/Test_Geolocation.html
    should contain    ${contents}   ${country}
    Remove file    ${EXECDIR}/${Geolocation}/*.html

Schedule Ping WBR Test in UFT
    [Arguments]    ${customer}    ${country}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    ${tag_1}  Create Dictionary    name=a_location    value=${country}
    @{parameters}=    Create List    ${tag_1}
    &{body}  Create Dictionary
    ...    testDefinitionPath=${testcases_path}/${customer}/Ping WBR
    ...    testDefinitionParameters=@{parameters}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${schedule}    headers=${headers}    json=${demo_body}
    log    ${response}    level=TRACE
    Should Be True     ${response.status_code} == 200
    ${order_ID}    get value from json     ${response.json()}    $.orderDetails.orderId
    log    ${order_ID}
    ${convertListToString}=   Evaluate             "".join(${order_ID})
    log    ${convertListToString}
    [Return]    ${convertListToString}

Run Ping WBR test and check status
    [Arguments]    ${client}    ${country}
    sleep    30s
    ${order_ID}=    Schedule Ping WBR Test in UFT    ${client}    ${country}
    log    ${order_ID}
    sleep    20s
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    orderId=${order_ID}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
             ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${test_status_UFT}    headers=${headers}    json=${demo_body}
             log    ${response}    level=TRACE
             sleep    30s
             ${verdict}    get value from json     ${response.json()}    $.testcaseStatusList[0].verdict
             log    ${verdict}
             ${status}    get value from json     ${response.json()}    $.testcaseStatusList[0].status
             log    ${status}
             ${status_Info}    get value from json     ${response.json()}    $.testcaseStatusList[0].statusInfo
             log    ${status_Info}
             ${status_check}=   Evaluate             "".join(${status})
             log    ${status_check}
             ${var}=    set variable if    '${status_check}' == '${done}' or '${status_check}' == '${aborted}'     ${verdict}
             exit for loop if    '${status_check}' == '${aborted}' or '${status_check}' == '${done}'
    END
    ${convertListToString}=   Evaluate             "".join(${var})
    log    ${convertListToString}
    ${convertListToString1}=   Evaluate             "".join(${status_Info})
    log    ${convertListToString1}
    IF    $location in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then change the location in UFT test case
    ELSE IF    $pdpcontext in $convertListToString1
        Fail    log    Need to rerun test one or two times.If same issue appeared multiple times then please check UFT test case configuration.
    ELSE IF    $webbrowsing in $convertListToString1
        Fail    log    This is either UFT issue or configuration issue. Rerun the test case one more time if same issue comes then please check the configuration.
    ELSE IF    $timeout in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then please check the configuration.
    ELSE
        Log    Either test case passed or any new error observed. please check Status Info.
    END
    should be equal    ${convertListToString}    ${passed_state}

Schedule Internet Breakout Test in UFT
    [Arguments]    ${customer}    ${country}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    ${tag_1}  Create Dictionary    name=a_location    value=${country}
    @{parameters}=    Create List    ${tag_1}
    &{body}  Create Dictionary
    ...    testDefinitionPath=${testcases_path}/${customer}/Google
    ...    testDefinitionParameters=@{parameters}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${schedule}    headers=${headers}    json=${demo_body}
    log    ${response}    level=TRACE
    Should Be True     ${response.status_code} == 200
    ${order_ID}    get value from json     ${response.json()}    $.orderDetails.orderId
    log    ${order_ID}
    ${convertListToString}=   Evaluate             "".join(${order_ID})
    log    ${convertListToString}
    [Return]    ${convertListToString}

Run Internet Breakout Test and check status
    [Arguments]    ${client}    ${country}
    sleep    30s
    ${order_ID}=    Schedule Internet Breakout Test in UFT   ${client}    ${country}
    log    ${order_ID}
    sleep    20s
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    orderId=${order_ID}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
             ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${test_status_UFT}    headers=${headers}    json=${demo_body}
             log    ${response}    level=TRACE
             sleep    30s
             ${verdict}    get value from json     ${response.json()}    $.testcaseStatusList[0].verdict
             log    ${verdict}
             ${status}    get value from json     ${response.json()}    $.testcaseStatusList[0].status
             log    ${status}
             ${status_Info}    get value from json     ${response.json()}    $.testcaseStatusList[0].statusInfo
             log    ${status_Info}
             ${test_UFT_id}    get value from json     ${response.json()}    $.testcaseStatusList[0].testcaseId
             log    ${test_UFT_id}
             ${status_check}=   Evaluate             "".join(${status})
             log    ${status_check}
             ${var}=    set variable if    '${status_check}' == '${done}' or '${status_check}' == '${aborted}'     ${verdict}
             exit for loop if    '${status_check}' == '${aborted}' or '${status_check}' == '${done}'
    END
    ${convertListToString}=   Evaluate             "".join(${var})
    log    ${convertListToString}
    ${convertListToString1}=   Evaluate             "".join(${status_Info})
    log    ${convertListToString1}
    ${testcase_id}=   Evaluate             "".join(${test_UFT_id})
    log    ${testcase_id}
    IF    $location in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then change the location in UFT test case
    ELSE IF    $pdpcontext in $convertListToString1
        Fail    log    Need to rerun test one or two times.If same issue appeared multiple times then please check UFT test case configuration.
    ELSE IF    $webbrowsing in $convertListToString1
        Fail    log    This is either UFT issue or configuration issue. Rerun the test case one more time if same issue comes then please check the configuration.
    ELSE IF    $timeout in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then please check the configuration.
    ELSE
        Log    Either test case passed or any new error observed. please check Status Info.
    END
    should be equal    ${convertListToString}    ${passed_state}
    [Return]    ${testcase_id}

Run Internet Breakout Test And Verify Exact Location for Specific APN
    [Arguments]    ${client}    ${Test}    ${Geolocation}    ${country}
    sleep    30s
    ${test_id}=    Run Internet Breakout Test and check status    ${client}    ${country}
    log    ${test_id}
    ${ip}=    Get local ip address of site    ${test_id}
    Log     ${ip}
    sleep    20s
    Set Log Level    Trace
    &{body}  Create Dictionary
    ...    testcaseId=${test_id}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    User-Agent=${user_agent}
    Download tracelogs    url_global=${global_roamer_url}/${resultfiles}   pkcs12_filename_roamer=${pkcs_directory}    pkcs12_password_roamer=${password_UFT}    destination_path_roamer=${dest_path_logs_us}/${Geolocation}    id_roam=${body}
    sleep    20s
    Remove files    ${EXECDIR}/${Geolocation}/*.sh    ${EXECDIR}/${Geolocation}/*.csv    ${EXECDIR}/${Geolocation}/*.zip    ${EXECDIR}/${Geolocation}/*.log    ${EXECDIR}/${Geolocation}/*.har    ${EXECDIR}/${Geolocation}/*.pcap
    sleep    10s
    ${status}=    Run keyword and return status    Move file    ${EXECDIR}/${Geolocation}/*.html    ${EXECDIR}/${Geolocation}/Test_Google.html
    sleep    5s
    Skip if    ${status} == ${False}    msg=Test case passed but intemittent API issue encountered while verifying the location.
    ${contents}=    get file    ${EXECDIR}/${Geolocation}/Test_Google.html
    should contain    ${contents}   ${Test}
    Remove file    ${EXECDIR}/${Geolocation}/*.html
    [Return]    ${ip}

Run Internet Breakout Test And Verify Exact Location for US APN
    [Arguments]    ${client}    ${Geolocation}    ${country}
    sleep    30s
    ${test_id}=    Run Internet Breakout Test and check status    ${client}    ${country}
    log    ${test_id}
    ${ip}=    Get local ip address of site    ${test_id}
    Log     ${ip}
    sleep    20s
    Set Log Level    Trace
    @{USlist}    create list    United States    France    Mexico   Canada    Australia    Nederland
    &{body}  Create Dictionary
    ...    testcaseId=${test_id}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    User-Agent=${user_agent}
    Download tracelogs    url_global=${global_roamer_url}/${resultfiles}   pkcs12_filename_roamer=${pkcs_directory}    pkcs12_password_roamer=${password_UFT}    destination_path_roamer=${dest_path_logs_us}/${Geolocation}    id_roam=${body}
    sleep    20s
    Remove files    ${EXECDIR}/${Geolocation}/*.sh    ${EXECDIR}/${Geolocation}/*.csv    ${EXECDIR}/${Geolocation}/*.zip    ${EXECDIR}/${Geolocation}/*.log    ${EXECDIR}/${Geolocation}/*.har    ${EXECDIR}/${Geolocation}/*.pcap
    sleep    10s
    ${status}=    Run keyword and return status     Move file    ${EXECDIR}/${Geolocation}/*.html    ${EXECDIR}/${Geolocation}/Test_Google.html
    log     ${status}
    sleep    5s
    Skip if    ${status} == ${False}    msg=Test case passed but intemittent API issue encountered while verifying the location.
    ${contents}=    get file    ${EXECDIR}/${Geolocation}/Test_Google.html
    should not contain any    ${contents}    @{USlist}
    Remove file    ${EXECDIR}/${Geolocation}/*.html
    [Return]    ${ip}

Schedule CBR Test in UFT
    [Arguments]    ${customer}    ${country}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    ${tag_1}  Create Dictionary    name=a_location    value=${country}
    @{parameters}=    Create List    ${tag_1}
    &{body}  Create Dictionary
    ...    testDefinitionPath=${testcases_path}/${customer}/CBR Enterprise
    ...    testDefinitionParameters=@{parameters}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${schedule}    headers=${headers}    json=${demo_body}
    log    ${response}    level=TRACE
    Should Be True     ${response.status_code} == 200
    ${order_ID}    get value from json     ${response.json()}    $.orderDetails.orderId
    log    ${order_ID}
    ${convertListToString}=   Evaluate             "".join(${order_ID})
    log    ${convertListToString}
    [Return]    ${convertListToString}

Run CBR Test and check status
    [Arguments]    ${client}    ${country}
    sleep    30s
    ${order_ID}=    Schedule CBR Test in UFT    ${client}    ${country}
    log    ${order_ID}
    sleep    20s
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    orderId=${order_ID}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
             ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${test_status_UFT}    headers=${headers}    json=${demo_body}
             log    ${response}    level=TRACE
             sleep    30s
             ${verdict}    get value from json     ${response.json()}    $.testcaseStatusList[0].verdict
             log    ${verdict}
             ${status}    get value from json     ${response.json()}    $.testcaseStatusList[0].status
             log    ${status}
             ${status_Info}    get value from json     ${response.json()}    $.testcaseStatusList[0].statusInfo
             log    ${status_Info}
             ${status_check}=   Evaluate             "".join(${status})
             log    ${status_check}
             ${var}=    set variable if    '${status_check}' == '${done}' or '${status_check}' == '${aborted}'     ${verdict}
             exit for loop if    '${status_check}' == '${aborted}' or '${status_check}' == '${done}'
    END
    ${convertListToString}=   Evaluate             "".join(${var})
    log    ${convertListToString}
    ${convertListToString1}=   Evaluate             "".join(${status_Info})
    log    ${convertListToString1}
    IF    $location in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then change the location in UFT test case
    ELSE IF    $pdpcontext in $convertListToString1
        Fail    log    Need to rerun test one or two times.If same issue appeared multiple times then please check UFT test case configuration.
    ELSE IF    $webbrowsing in $convertListToString1
        Fail    log    This is either UFT issue or configuration issue. Rerun the test case one more time if same issue comes then please check the configuration.
    ELSE IF    $timeout in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then please check the configuration.
    ELSE
        Log    Either test case passed or any new error observed. please check Status Info.
    END
    should be equal    ${convertListToString}    ${passed_state}

Schedule DL Multiple TCP Capacity Test in UFT
    [Arguments]    ${customer}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    testDefinitionPath=${testcases_path}/${customer}/HTTP_DL_multiple_TCP_Capacity
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${schedule}    headers=${headers}    json=${demo_body}
    log    ${response}    level=TRACE
    Should Be True     ${response.status_code} == 200
    ${order_ID}    get value from json     ${response.json()}    $.orderDetails.orderId
    log    ${order_ID}
    ${convertListToString}=   Evaluate             "".join(${order_ID})
    log    ${convertListToString}
    [Return]    ${convertListToString}

Run DL Multiple TCP Capacity Test and check status
    [Arguments]    ${client}
    sleep    30s
    ${order_ID}=    Schedule CBR Test in UFT    ${client}
    log    ${order_ID}
    sleep    20s
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    orderId=${order_ID}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
             ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${test_status_UFT}    headers=${headers}    json=${demo_body}
             log    ${response}    level=TRACE
             sleep    30s
             ${verdict}    get value from json     ${response.json()}    $.testcaseStatusList[0].verdict
             log    ${verdict}
             ${status}    get value from json     ${response.json()}    $.testcaseStatusList[0].status
             log    ${status}
             ${status_check}=   Evaluate             "".join(${status})
             log    ${status_check}
             ${var}=    set variable if    '${status_check}' == '${done}'    ${verdict}
             exit for loop if    '${status_check}' == '${done}'
    END
    ${convertListToString}=   Evaluate             "".join(${var})
    log    ${convertListToString}
    should be equal    ${convertListToString}    ${passed_state}

Schedule Ping Internet Test in UFT
    [Arguments]    ${customer}    ${country}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    ${tag_1}  Create Dictionary    name=a_location    value=${country}
    @{parameters}=    Create List    ${tag_1}
    &{body}  Create Dictionary
    ...    testDefinitionPath=${testcases_path}/${customer}/Ping_ps8
    ...    testDefinitionParameters=@{parameters}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${schedule}    headers=${headers}    json=${demo_body}
    log    ${response}    level=TRACE
    Should Be True     ${response.status_code} == 200
    ${order_ID}    get value from json     ${response.json()}    $.orderDetails.orderId
    log    ${order_ID}
    ${convertListToString}=   Evaluate             "".join(${order_ID})
    log    ${convertListToString}
    [Return]    ${convertListToString}

Run Ping Internet test and check status
    [Arguments]    ${client}    ${country}
    sleep    30s
    ${order_ID}=      Schedule Ping Internet Test in UFT   ${client}    ${country}
    log    ${order_ID}
    sleep    20s
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    orderId=${order_ID}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
             ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${test_status_UFT}    headers=${headers}    json=${demo_body}
             log    ${response}    level=TRACE
             sleep    30s
             ${verdict}    get value from json     ${response.json()}    $.testcaseStatusList[0].verdict
             log    ${verdict}
             ${status}    get value from json     ${response.json()}    $.testcaseStatusList[0].status
             log    ${status}
             ${status_Info}    get value from json     ${response.json()}    $.testcaseStatusList[0].statusInfo
             log    ${status_Info}
             ${status_check}=   Evaluate             "".join(${status})
             log    ${status_check}
             ${var}=    set variable if    '${status_check}' == '${done}' or '${status_check}' == '${aborted}'     ${verdict}
             exit for loop if    '${status_check}' == '${aborted}' or '${status_check}' == '${done}'
    END
    ${convertListToString}=   Evaluate             "".join(${var})
    log    ${convertListToString}
    ${convertListToString1}=   Evaluate             "".join(${status_Info})
    log    ${convertListToString1}
    IF    $location in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then change the location in UFT test case
    ELSE IF    $pdpcontext in $convertListToString1
        Fail    log    Need to rerun test one or two times.If same issue appeared multiple times then please check UFT test case configuration.
    ELSE IF    $webbrowsing in $convertListToString1
        Fail    log    This is either UFT issue or configuration issue. Rerun the test case one more time if same issue comes then please check the configuration.
    ELSE IF    $timeout in $convertListToString1
        Fail    log    Need to rerun test one more time if issue persist then please check the configuration.
    ELSE
        Log    Either test case passed or any new error observed. please check Status Info.
    END
    should be equal    ${convertListToString}    ${passed_state}

Get local ip address of site
    [Arguments]    ${Test}
    Set Log Level    Trace
    ${resp}    Create Pkcs12 Session
    ...    Automation
    ...    ${global_roamer_url}
    ...    ${EXECDIR}/${certicate_dir}/Automation_us_api.p12
    ...    ${password_UFT}
    log    ${resp}
    &{body}  Create Dictionary
    ...    testcaseId=${Test}
    ${body}  Evaluate    json.dumps(&{body})    json
    log    ${body}
    ${demo_body}=    convert string to json    ${body}
    log    ${demo_body}
    ${headers}=  Create Dictionary   Accept=${aster}    Host=api.Automation.com    Connection=keep-alive    Content-Type=${accept}    Accept-Encoding=gzip, deflate, br    User-Agent=${user_agent}
    Set Test Variable    ${success_num}    ${0}
    FOR    ${item}    IN RANGE    1000000
            ${response}=    ExtendedHTTPLibrary.POST On Session    Automation    ${kpi}    headers=${headers}    json=${demo_body}
            log    ${response}    level=TRACE
            ${ip_address}    get value from json     ${response.json()}    $.kpiRowList[0][${success_num}].name
            log    ${ip_address}
            ${ip_value}    get value from json     ${response.json()}    $.kpiRowList[0][${success_num}].value
            log    ${ip_value}
            Should Be True     ${response.status_code} == 200
            ${status_check}=   Evaluate             "".join(${ip_address})
            log    ${status_check}
            ${var}=    set variable if    '${status_check}' == '${local_ip}'    ${ip_value}
            exit for loop if    '${status_check}' == '${local_ip}'
            ${success_num}=    Evaluate    ${success_num} + 1
            log    ${success_num}
    END
    ${ip_addr}=   Evaluate             "".join(${ip_value})
    log    ${ip_addr}
    ${2nd_octet}=    split string    ${ip_addr}    .    2
    log    ${2nd_octet}[1]
    [Return]    ${2nd_octet}[1]
