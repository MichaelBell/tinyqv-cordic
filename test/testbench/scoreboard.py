"""
  Copyright (c) 2025 Dylan Toussaint
  SPDX-License-Identifier: Apache-2.0
"""

from __future__ import annotations
from typing import Any, Callable, Optional
import pprint

import cocotb
from cocotb.queue import Queue
from cocotb.triggers import with_timeout, NullTrigger

class Scoreboard:
    """
    Generic Scoreboard Class
    Compares Model and Dut transactions
    """

    _DONE = object()

    def __init__(
        self,
        name: str = "scoreboard",
        *,
        comparator: Optional[Callable[[Any, Any], bool]] = None,
        formatter: Optional[Callable[[Any], str]] = None,
        timeout: Optional[int] = 10000,
        time_units: str = "us",
    ):
        self.name           = name
        self.model_q: Queue = Queue()
        self.dut_q:   Queue = Queue()
        self._cmp           = comparator or (lambda a, b: a == b)
        self._fmt           = formatter or (lambda x: pprint.pformat(x, width=100))

        self._model_done    = False
        self._dut_done      = False
        self._count         = 0
        self._task: Optional[cocotb.task.Task] = None
        self._timeout       = timeout
        self._time_units     = time_units

    def start(self) -> None:
       """Await completion of checker task."""
       if self._task is None:
          self._task = cocotb.start_soon(self._checker())
    
    async def wait(self) -> None:
       if self._task is not None:
          await self._task

    async def model_done(self) -> None:
       await self.model_q.put(self._DONE)
    
    async def dut_done(self) -> None:
       await self.dut_q.put(self._DONE)
    
    async def _get(self, q:Queue):
       return await with_timeout(q.get(), self._timeout, self._time_units)
    
    async def _checker(self) -> None:
       """Comparison Loop"""
       while True:
          m = await self._get(self.model_q)
          d = await self._get(self.dut_q)

          if m is self._DONE:
             self._model_done = True
          if d is self._DONE:
             self._dut_done   = True

          if self._model_done and self._dut_done:
            assert m is self._DONE and d is self._DONE, (
                f"{self.name}: length mismatch at end (model_done={self._model_done}, dut_done={self._dut_done})"
            )
            return
          
          assert not self._model_done and not self._dut_done, (
             f"{self.name}: length mismatch: model_done={self._model_done}, dut_done={self._dut_done}"
          )

          ok = False
          try:
             ok = self._cmp(d, m)
          except Exception as e:
             raise AssertionError(
                f"{self.name}: comparator raised at item:\n"
                f"  model: {self._fmt(m)} \n"
                f"  dut:   {self._fmt(d)} \n"
                f"  error: {e}"
             )
          
          assert ok, (
                f"{self.name}: MISMATCH at item:\n"
                f"  model: {self._fmt(m)} \n"
                f"  dut:   {self._fmt(d)} \n"
          )
        

            
