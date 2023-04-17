#include <stdio.h>
#include <glib.h>
#include <gio/gio.h>
#include <fcntl.h>
#include <unistd.h>

/* Globals */
static GIOChannel     *input;
/* Context */
static gchar    *device_str;

static GOptionEntry main_entries[] = {
    { "device", 'd', 0, G_OPTION_ARG_STRING, &device_str,
      "Specify device path",
      "[PATH]"
    },
    { NULL }
};

int main (int argc, char **argv)
{
    GOptionContext *context;
    GByteArray *command;
    int fd;
    int result = TRUE;
    GIOStatus write_status;
    gsize idx = 0;
    gsize written = 0;
    GError *error = NULL;
    gssize send_len;
    const gchar *p;

    /* Setup option context, process it and destroy it */
    context = g_option_context_new ("- ModemManager AT testing");
    g_option_context_add_main_entries (context, main_entries, NULL);
    g_option_context_parse (context, &argc, &argv, NULL);
    g_option_context_free (context);

    /* No device path given? */
    if (!device_str) {
        g_printerr ("error: no device path specified\n");
        exit (EXIT_FAILURE);
    }

    command = g_byte_array_sized_new (4);
    g_byte_array_append (command, (const guint8 *) "AT", 2);
    g_byte_array_append (command, (const guint8 *) "\r", 1);
    g_byte_array_append (command, (const guint8 *) "\n", 1);
    for (int i = 0; i < 4; i++)
	    printf("%d\n", command->data[i]);

    /* Send the whole command in one write */
    send_len = (gssize)command->len;
    p = (gchar *)command->data;

    fd = open (device_str, O_RDWR | O_EXCL | O_NONBLOCK | O_NOCTTY);
    if (fd < 0) {
	    printf("Could not open serial device %s\n", device_str);
	    result = FALSE;
	    goto error_f;
    }
    input = g_io_channel_unix_new (fd);
    /* We don't want UTF-8 encoding, we're playing with raw binary data */
    g_io_channel_set_encoding (input, NULL, NULL);
    /* We don't want to get the channel buffered */
    g_io_channel_set_buffered (input, FALSE);

    /* We don't want to get blocked while writing stuff */
    if (!g_io_channel_set_flags (input, G_IO_FLAG_NONBLOCK, &error)) {
	    result = FALSE;
	    goto error_f;
    }
    for (int j = 0; j < 10; j++) {
        /* Send N bytes of the command */
        write_status = g_io_channel_write_chars (input, p, send_len, &written, &error);
        switch (write_status) {
            case G_IO_STATUS_ERROR:
                result = FALSE;
    	        printf("written failed\n");
    	        goto error_f;
    
            case G_IO_STATUS_EOF:
                /* We shouldn't get EOF when writing */
                g_assert_not_reached ();
                break;
    
            case G_IO_STATUS_NORMAL:
                if (written > 0) {
                    idx += written;
    		    printf("I've already written %lu bytes\n", idx);
                    break;
                }
            case G_IO_STATUS_AGAIN:
    	        printf("Need try again!!\n");
        }
        /* Sleep 5 seconds and send again*/
	sleep(5);
    }

error_f:
    if (command)
        g_byte_array_free (command, TRUE);
    if (input)
        g_io_channel_unref (input);
    if (fd >= 0)
        close (fd);

    return result;
}
