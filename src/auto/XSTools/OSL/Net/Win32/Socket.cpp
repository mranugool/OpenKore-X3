/*
 *  OpenKore C++ Standard Library
 *  Copyright (C) 2006,2007  VCL
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *  MA  02110-1301  USA
 */

// Do not compile this file independently, it's supposed to be automatically
// included by another source file.

#include "Socket.h"

namespace OSL {
namespace _Intern {

	static void
	initWinSock() {
		WORD version;
		WSADATA data;

		version = MAKEWORD(2, 2);
		WSAStartup(version, &data);
	}


	/**
	* @internal
	* An internal class which implements WinSocket's input stream.
	*/
	class InStream: public InputStream {
	private:
		SOCKET fd;
		bool closed;
		bool m_eof;
	public:
		InStream(SOCKET fd) {
			this->fd = fd;
			m_eof = false;
			closed = false;
		}

		virtual void
		close() {
			if (!closed) {
				shutdown(fd, SD_RECEIVE);
				closed = true;
			}
		}

		virtual bool
		eof() const throw(IOException) {
			return m_eof;
		}

		virtual int
		read(char *buffer, unsigned int size) throw(IOException) {
			assert(buffer != NULL);
			assert(size > 0);

			if (m_eof) {
				return -1;
			}

			ssize_t result = ::recv(fd, buffer, size, 0);
			if (result == SOCKET_ERROR) {
				throw IOException("Unable to receive data.", WSAGetLastError());
			} else if (result == 0) {
				m_eof = true;
				return -1;
			} else {
				return result;
			}
		}
	};

	/**
	* @internal
	* An internal class which implements WinSocket's output stream.
	*/
	class OutStream: public OutputStream {
	private:
		SOCKET fd;
		bool closed;
	public:
		OutStream(SOCKET fd) {
			this->fd = fd;
			closed = false;
		}

		virtual void
		close() {
			if (!closed) {
				shutdown(fd, SD_RECEIVE);
				closed = true;
			}
		}

		virtual void
		flush() throw(IOException) {
		}

		virtual unsigned int
		write(const char *data, unsigned int size) throw(IOException) {
			assert(data != NULL);
			assert(size > 0);

			ssize_t result = ::send(fd, data, size, 0);
			if (result == SOCKET_ERROR) {
				throw IOException("Unable to send data.", WSAGetLastError());
			}
			return result;
		}
	};


	WinSocket::WinSocket(const char *address, unsigned short port) {
		fd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
		if (fd == INVALID_SOCKET) {
			char message[100];
			int error = WSAGetLastError();
			snprintf(message, sizeof(message),
				"Cannot create socket. (error %d)",
				error);
			throw SocketException(message, error);
		}

		struct hostent *ent;
		char *ip;
		ent = gethostbyname(address);
		if (ent == NULL) {
			char message[200];
			int error = WSAGetLastError();
			snprintf(message, sizeof(message),
				"Host %s not found.",
				address);
			closesocket(fd);
			throw HostNotFoundException(message, error);
		}
		ip = inet_ntoa(*(struct in_addr *)*ent->h_addr_list);

		sockaddr_in addr;
		addr.sin_family = AF_INET;
		addr.sin_port = htons(port);
		addr.sin_addr.s_addr = inet_addr(ip);
		if (connect(fd, (const struct sockaddr *) &addr, sizeof(addr)) == SOCKET_ERROR) {
			char message[300];
			int error = WSAGetLastError();
			snprintf(message, sizeof(message),
				"Cannot connect to %s:%d: error %d",
				address, port, error);
			closesocket(fd);
			throw SocketException(message, error);
		}

		in = new InStream(fd);
		out = new OutStream(fd);
	}

	WinSocket::WinSocket(SOCKET sock) {
		assert(sock != INVALID_SOCKET);
		fd = sock;
		in = new InStream(fd);
		out = new OutStream(fd);
	}

	WinSocket::~WinSocket() {
		in->close();
		in->unref();
		out->close();
		out->unref();
		closesocket(fd);
	}

	InputStream *
	WinSocket::getInputStream() const {
		return in;
	}

	OutputStream *
	WinSocket::getOutputStream() const {
		return out;
	}

} // namespace _Intern
} // namespace OSL
