import logging
from typing import Any, Text, Dict, List
import json
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import UserUtteranceReverted
import requests
from sqlalchemy import create_engine, text
import timeit

class ActionDefaultFallback(Action):
    def name(self) -> Text:
        return "action_default_fallback"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        try:
            # Start measuring execution time
            function_start_time = timeit.default_timer()
            logging.info("Action start time: %s", function_start_time)
            
            # Connect to PostgreSQL database using SQLAlchemy
            engine = create_engine(
                "postgresql://postgres:GR2PxQ{4.e.:Z62L}$_h0w)C00Sk@rasa-database.cej5rr5cdy4b.us-east-1.rds.amazonaws.com:5432/chatbot"
            )
            sender_id = str(tracker.sender_id)
            logging.info("Sender ID: %s", sender_id)
            
            # Execute SQL query to fetch chat history
            query_start_time = timeit.default_timer()
            logging.info("SQL query start time: %s", query_start_time)
            query = text("""
                WITH user_conversations AS (
                    SELECT
                        sender_id,
                        ARRAY_AGG(
                            json_build_object(
                                'user_timestamp', TO_CHAR(TO_TIMESTAMP(timestamp::double precision), 'YYYY-MM-DD HH24:MI:SS'),
                                'User', (data::jsonb)->>'text',
                                'type', 'user_message'
                            ) ORDER BY timestamp DESC
                        ) AS user_messages
                    FROM (
                        SELECT
                            sender_id,
                            timestamp,
                            data,
                            ROW_NUMBER() OVER (PARTITION BY sender_id ORDER BY timestamp DESC) AS row_num
                        FROM
                            events
                        WHERE
                            type_name = 'user'
                            AND sender_id = :sender_id
                            AND (data::jsonb)->>'text' IS NOT NULL
                    ) AS numbered_messages
                    WHERE
                        row_num <= 3
                    GROUP BY
                        sender_id
                ),
                advisor_conversations AS (
                    SELECT
                        sender_id,
                        ARRAY_AGG(
                            json_build_object(
                                'assistant_timestamp', TO_CHAR(TO_TIMESTAMP(timestamp::double precision), 'YYYY-MM-DD HH24:MI:SS'),
                                'AI Advisor', (data::jsonb)->>'text',
                                'type', 'ai_response'
                            ) ORDER BY timestamp DESC
                        ) AS advisor_responses
                    FROM (
                        SELECT
                            sender_id,
                            timestamp,
                            data,
                            ROW_NUMBER() OVER (PARTITION BY sender_id ORDER BY timestamp DESC) AS row_num
                        FROM
                            events
                        WHERE
                            type_name = 'bot'
                            AND sender_id = :sender_id
                            AND (data::jsonb)->>'text' IS NOT NULL
                    ) AS numbered_messages
                    WHERE
                        row_num <= 3
                    GROUP BY
                        sender_id
                )
                SELECT
                    COALESCE(uc.sender_id, ac.sender_id) AS sender_id,
                    COALESCE(uc.user_messages, '{}'::json[]) AS user_messages,
                    COALESCE(ac.advisor_responses, '{}'::json[]) AS advisor_responses
                FROM
                    user_conversations uc
                FULL JOIN advisor_conversations ac ON uc.sender_id = ac.sender_id;
            """)

            # Execute the query and fetch chat history records
            with engine.connect() as conn:
                result = conn.execute(query, sender_id=sender_id)
                chat_history_record = result.fetchone()

            # Prepare chat history from database records
            if chat_history_record is not None:

                user_messages = [msg['User'] for msg in chat_history_record[1] if 'User' in msg]
                advisor_responses = [msg['AI Advisor'] for msg in chat_history_record[2] if 'AI Advisor' in msg]
                logging.info("chat_history: %s", advisor_responses)
                
            else:
                user_messages = []
                advisor_responses = []
                
            # Check if advisor_responses is empty or contains only None values
            if not advisor_responses or all(response is None for response in advisor_responses):
                advisor_responses = []
            user_message = tracker.latest_message.get("text")
            
            # Prepare data for Databricks API
            data_for_databricks = {
                "dataframe_split": {
                    "columns": ["query", "chat_history"],
                    "data": [[user_message], {"User": user_messages, "AI Advisor": advisor_responses}]
                }
            }
            payload = json.dumps(data_for_databricks)
            # Databricks API endpoint and headers
            databricks_endpoint = "databricks-endpoint-url"

             ) -> List[Dict[Text, Any]]:
        try:
            # Start measuring execution time
            function_start_time = timeit.default_timer()
            logging.info("Action start time: %s", function_start_time)
            
            # Connect to PostgreSQL database using SQLAlchemy
            engine = create_engine(
                "postgresql://postgres:GR2PxQ{4.e.:Z62L}$_h0w)C00Sk@rasa-database.cej5rr5cdy4b.us-east-1.rds.amazonaws.com:5432/chatbot"
            )
            sender_id = str(tracker.sender_id)
            logging.info("Sender ID: %s", sender_id)
            
            # Execute SQL query to fetch chat history
            query_start_time = timeit.default_timer()
            logging.info("SQL query start time: %s", query_start_time)
            query = text("""
                WITH user_conversations AS (
                    SELECT
                        sender_id,
            f    ) -> List[Dict[Text, Any]]:
        try:
            # Start measuring execution time
            function_start_time = timeit.default_timer()
            logging.info("Action start time: %s", function_start_time)
            
            # Connect to PostgreSQL database using SQLAlchemy
            engine = create_engine(
                "postgresql://postgres:GR2PxQ{4.e.:Z62L}$_h0w)C00Sk@rasa-database.cej5rr5cdy4b.us-east-1.rds.amazonaws.com:5432/chatbot"
            )
            sender_id = str(tracker.sender_id)
            logging.info("Sender ID: %s", sender_id)
            
            # Execute SQL query to fetch chat history
            query_start_time = timeit.default_timer()
            logging.info("SQL query start time: %s", query_start_time)
            query = text("""
                WITH user_conversations AS (
                    SELECT
                        sender_id,
