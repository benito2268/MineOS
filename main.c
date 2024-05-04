
void kmain(void) 
{
	// try to put something on the screen
	unsigned short *vga_buf = (unsigned short*)0xb8000;
	vga_buf[0] = 0b000111101100001;

	for(;;) { } 
}
