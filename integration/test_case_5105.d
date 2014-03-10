synchronized class C
{
	template foo(T)
	{
		void foo(T a) {}
	}
}

void main()
{
   auto c = new C;
   c.foo(10);
}

