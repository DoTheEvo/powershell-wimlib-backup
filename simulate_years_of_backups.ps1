# wont work on windows 7 because of Get-ScheduledTask
# it will change date and time on the machine running it

$scheduled_task_name = "wimlib_backup_test"

function add_24_hours_and_make_backup(){
    Set-Date (Get-Date).AddHours(+24)
    Start-ScheduledTask -TaskName $scheduled_task_name
}

1..97 | % {
    add_24_hours_and_make_backup
    while ((Get-ScheduledTask -TaskName $scheduled_task_name).State  -ne 'Ready') {}
}
