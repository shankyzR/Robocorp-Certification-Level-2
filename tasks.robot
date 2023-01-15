*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault

Suite Setup         Run Keyword    Setup Steps
Suite Teardown      Run Keyword    Teardown Steps


*** Variables ***
${output_folder}        ${CURDIR}${/}output
${receipts_folder}      ${output_folder}${/}receipts
${images_folder}        ${output_folder}${/}images
${downloaded_file}      ${CURDIR}${/}orders.csv
${zip_file}             ${output_folder}${/}receipts.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=    Get Robot Order Website URL from Vault
    ${csv_file}=    Get CSV File Location from User
    Open the robot order website    ${url}
    ${orders}=    Get orders    ${csv_file}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    0.5 sec    Submit the order
        Take screenshot embed and store pdf    ${row}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Setup Steps
    ${csv_file_presence}=    Does File Exist    ${downloaded_file}
    IF    '${csv_file_presence}'=='True'    Remove File    ${downloaded_file}
    ${zip_file_presence}=    Does File Exist    ${zip_file}
    IF    '${zip_file_presence}'=='True'    Remove File    ${zip_file}
    Create Directory    ${receipts_folder}
    Create Directory    ${images_folder}

Teardown Steps
    Remove File    ${downloaded_file}
    Remove Directory    ${receipts_folder}    True
    Remove Directory    ${images_folder}    True
    Close Window

Get Robot Order Website URL from Vault
    ${website}=    Get Secret    website
    RETURN    ${website}[url]

Get CSV File Location from User
    Add heading    CSV file details for all Orders
    Add text input    path    label=What is the URL for the order CSV file?    placeholder=Give link details
    ${result}=    Run dialog
    RETURN    ${result.path}

Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}
    Maximize Browser Window

Get orders
    [Arguments]    ${csv_file}
    Download    ${csv_file}    target_file=${downloaded_file}    overwrite=True
    ${orders}=    Read table from CSV    ${downloaded_file}    header=True
    RETURN    ${orders}

Close the annoying modal
    Wait and Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${row}
    log    ${row}
    Select From List By Value    //select[@name="head"]    ${row}[Head]
    Click Element    //input[@value="${row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@id="address"]    ${row}[Address]

Preview the robot
    Click Button    //button[@id="preview"]
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]

Submit the order
    Click Button    //button[@id="order"]
    Page Should Contain Element    id=receipt
    Page Should Contain Element    id=order-another

Take screenshot embed and store pdf
    [Arguments]    ${row}
    ${receipt_info}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_info}    ${receipts_folder}${/}${row}[Order number].pdf
    Screenshot    //div[@id="robot-preview-image"]    ${images_folder}${/}${row}[Order number].png
    Add Watermark Image To Pdf
    ...    ${images_folder}${/}${row}[Order number].png
    ...    ${receipts_folder}${/}${row}[Order number].pdf
    ...    ${receipts_folder}${/}${row}[Order number].pdf

Go to order another robot
    Click Button    //button[@id="order-another"]

Create a ZIP file of the receipts
    Archive Folder With Zip    ${receipts_folder}    ${output_folder}${/}receipts.zip
