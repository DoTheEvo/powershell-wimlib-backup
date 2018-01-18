# wont work on windows 7 because of Get-ScheduledTask
# this script changes date and time on the machine running it, beware

$scheduled_task_name = 'test'

function add_24_hours_and_make_backup(){
    Set-Date (Get-Date).AddHours(+24)
    Start-ScheduledTask -TaskPath 'wimlib_backup' -TaskName $scheduled_task_name
}

1..97 | % {
    add_24_hours_and_make_backup
    while ((Get-ScheduledTask -TaskName $scheduled_task_name).State  -ne 'Ready') {}
}
