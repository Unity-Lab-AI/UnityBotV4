import asyncio
import logging
from dataclasses import dataclass
import discord

logger = logging.getLogger(__name__)

@dataclass
class QueueItem:
    message: discord.Message
    user_id: str
    timestamp: float

class MessageQueueSystem:
    def __init__(self, bot, handler):
        self.bot = bot
        self.handler = handler
        self.user_queue = asyncio.Queue()
        self.bot_queue = asyncio.Queue()
        self.last_send_time = 0.0
        self.last_bot_send_time = 0.0
        self.queue_task = None

    def start(self):
        if self.queue_task is None:
            self.queue_task = asyncio.create_task(self.process_queues())

    async def enqueue(self, message: discord.Message):
        item = QueueItem(message=message, user_id=str(message.author.id), timestamp=asyncio.get_event_loop().time())
        if message.author.bot:
            await self.bot_queue.put(item)
            logger.debug(f"Enqueued bot message from {item.user_id}")
        else:
            await self.user_queue.put(item)
            logger.debug(f"Enqueued user message from {item.user_id}")

    async def process_queues(self):
        while True:
            processed = False
            now = asyncio.get_event_loop().time()
            if not self.user_queue.empty():
                item = await self.user_queue.get()
                await self._ensure_delays(item.timestamp)
                async with item.message.channel.typing():
                    await self._handle_item(item)
                self.last_send_time = asyncio.get_event_loop().time()
                processed = True
            elif not self.bot_queue.empty() and (now - self.last_bot_send_time) >= 300:
                item = await self.bot_queue.get()
                await self._ensure_delays(item.timestamp)
                async with item.message.channel.typing():
                    await self._handle_item(item)
                current = asyncio.get_event_loop().time()
                self.last_send_time = current
                self.last_bot_send_time = current
                processed = True
            if not processed:
                await asyncio.sleep(1)

    async def _ensure_delays(self, msg_timestamp: float):
        now = asyncio.get_event_loop().time()
        wait = 5 - (now - msg_timestamp)
        if wait > 0:
            await asyncio.sleep(wait)
        now = asyncio.get_event_loop().time()
        wait = 5 - (now - self.last_send_time)
        if wait > 0:
            await asyncio.sleep(wait)

    async def _handle_item(self, item: QueueItem):
        try:
            await self.bot.process_commands(item.message)
            await self.handler.handle_message(item.message)
            await self.bot.data_manager.save_data_async(self.bot.memory_manager)
            channel_id = str(item.message.channel.id)
            max_history = self.handler.config.max_history
            histories = self.bot.memory_manager.channel_histories
            if len(histories.get(channel_id, [])) > max_history:
                histories[channel_id] = histories[channel_id][-max_history:]
        except Exception as e:
            logger.error(f"Error processing message from {item.user_id}: {e}")
