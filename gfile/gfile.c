#include <stdio.h>
#include <gio/gio.h>

// callback function when file added, deleted, changed
static void file_changed(GFileMonitor *monitor, GFile *file, GFile *other_file, GFileMonitorEvent event_type, gpointer user_data)
{
    switch (event_type) {
    case G_FILE_MONITOR_EVENT_CHANGED:
        g_print("File %s changed\n", g_file_get_parse_name(file));
        break;
    case G_FILE_MONITOR_EVENT_CREATED:
        g_print("File %s created\n", g_file_get_parse_name(file));
        break;
    case G_FILE_MONITOR_EVENT_DELETED:
        g_print("File %s deleted\n", g_file_get_parse_name(file));
        break;
    default:
        g_print("Unknown event %d\n", event_type);
        break;
    }
}

int main(int argc, char *argv[])
{
    GFileMonitor *monitor;
    GMainLoop *main_loop;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    monitor = g_file_monitor_file(g_file_new_for_path(argv[1]), G_FILE_MONITOR_NONE, NULL, NULL);
    g_signal_connect(monitor, "changed", G_CALLBACK(file_changed), NULL);

    main_loop = g_main_loop_new(NULL, FALSE);
    g_main_loop_run(main_loop);

    exit(EXIT_SUCCESS);
}
