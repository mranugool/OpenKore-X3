/*  Kore Shared Data Server
 *  Copyright (C) 2005  Hongli Lai <hongli AT navi DOT cx>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/poll.h>
#include <sys/un.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>

#include "unix-server.h"
#include "client.h"
#include "threads.h"


#define LOCKFILE "/tmp/kore-dataserver.lock"


/* Create a lockfile so you can't run two servers at the same time.
 * This will also allow processes to check whether the server is already running.
 *
 * Returns:
 * -1 (error)
 *  0 (already locked by another process)
 *  1 (sucessfully locked)
 */
int
unix_server_trylock ()
{
	int fd, already_locked;

	/* First, check whether the existing file is locked. */
	fd = open (LOCKFILE, O_RDONLY);
	if (fd == -1 && errno != ENOENT) {
		/* Cannot open file, but it's not because the file doesn't exist. */
		char msg[1024];

		snprintf (msg, sizeof (msg), "datserver: Cannot open lock file %s", LOCKFILE);
		perror (msg);
		return -1;

	} else if (fd != -1) {
		already_locked = flock (fd, LOCK_EX | LOCK_NB) == -1;
		close (fd);
		if (already_locked)
			/* File already locked. There's already a server running. */
			return 0;
	}

	/* Lock file does not exist, or is not locked.
	 * Create a new lockfile and lock it. */
	fd = open (LOCKFILE, O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	if (fd == -1) {
		perror ("dataserver: Cannot create lock file");
		return -1;
	}

	flock (fd, LOCK_EX);
	return 1;
}


UnixServer *
unix_server_new (char *filename, NewClientCallback callback)
{
	int fd;
	struct sockaddr_un addr;
	UnixServer *server;

	/* Create Unix Domain Socket. */
	fd = socket (PF_UNIX, SOCK_STREAM, 0);
	if (fd == -1)
		return NULL;

	/* Bind to a filename. */
	addr.sun_family = AF_UNIX;
	strncpy (addr.sun_path, filename, 107);
	remove (filename);
	if (bind (fd, (struct sockaddr *) &addr, sizeof (addr)) == -1) {
		perror ("dataserver: cannot bind server socket");
		close (fd);
		return NULL;
	}

	/* Setup listen queue. */
	if (listen (fd, 5) == -1) {
		perror ("dataserver: cannot setup server socket for listening");
		close (fd);
		return NULL;
	}

	/* Ready to rock. */
	server = malloc (sizeof (UnixServer));
	server->fd = fd;
	server->callback = callback;
	server->filename = filename;
	server->stop = 0;
	server->retval = 0;
	return server;
}


void
unix_server_main_loop (UnixServer *server)
{
	while (!server->stop) {
		struct pollfd ufds;
		struct sockaddr_un addr;
		socklen_t addr_len;
		int fd, tmp;
		Client *client;

		/* Check whether there are incoming connections. */
		ufds.fd = server->fd;
		ufds.events = POLLIN;
		tmp = poll (&ufds, 1, 500);
		if (tmp == -1) {
			/* Error. But it's OK if the system call was interrupted
			 * (by Ctrl-C or whatever). */
			if (errno != EINTR) {
				perror ("dataserver: Cannot poll server socket");
				server->retval = 1;
			}
			return;

		} else if (tmp == 0)
			/* No incoming connections. */
			continue;


		/* Accept incoming connection. */
		addr_len = sizeof (addr);
		do {
			fd = accept (server->fd, (struct sockaddr *) &addr, &addr_len);
		} while (fd == -1 && errno == EINTR);
		if (fd == -1) {
			/* Accept failed but the error is not EINTR. */
			perror ("dataserver: Cannot accept connection");
			server->retval = 1;
			return;
		}

		/* Create a Client structure and pass it to the callback. */
		client = malloc (sizeof (Client));
		client->fd = fd;
		client_init (client);
		server->callback (client);
	}
}


int
unix_server_free (UnixServer *server)
{
	int retval;

	retval = server->retval;
	close (server->fd);
	remove (server->filename);
	free (server->filename);
	free (server);
	remove (LOCKFILE);

	return retval;
}
