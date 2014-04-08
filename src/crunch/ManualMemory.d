module crunch.ManualMemory;

mixin template ManualMemory()
{
	import core.memory;
	private void acquireMemory()
	{
		mixin(Tracer);
		GC.addRoot(cast(void*)&this);
        GC.setAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
	}

	private void releaseMemory()
	{
		mixin(Tracer);
		GC.removeRoot(cast(void*)&this);
        GC.clrAttr(cast(void*)&this, GC.BlkAttr.NO_MOVE);
	}
}
