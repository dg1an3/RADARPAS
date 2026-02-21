u_short GetServiceByName(char *service, char *protocol) {
	struct servent *serviceEntry;
	serviceEntry = getservbyname(service, protocol);
	if (serviceEntry != NULL)
		return serviceEntry->s_port;
	else if (strcmp(service, "http") == 0)
		return htons(80);	// well-known port for http
	TRACE("Service not found!!!\n");
	return 0;
}	// GetServiceByName

u_short GetProtocolByName(char *protocol) {
	struct protoent *pProtoEntry;    // pointer to protocol entry
	if ((pProtoEntry = getprotobyname(protocol)) != 0)  // map protocol name to protocol number
		return pProtoEntry->p_proto;
	else if (strcmp(protocol, "tcp") == 0)
		return 6;
	TRACE("Protocol not found!\n");
	return 0;
}	// GetProtocolByName

