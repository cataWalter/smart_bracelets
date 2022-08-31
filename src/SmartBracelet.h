// Message struct

typedef nx_struct msggtype{
	nx_uint8_t type;
	nx_uint8_t key[20];
	nx_uint16_t source;
	nx_uint16_t dest;
	nx_uint8_t status;
	nx_uint8_t x;
	nx_uint8_t y;
	
	
} msggtype;
