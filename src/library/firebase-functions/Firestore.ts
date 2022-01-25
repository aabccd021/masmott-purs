import { EventContext, firestore } from 'firebase-functions';
import { DocumentBuilder } from 'firebase-functions/v1/firestore';
import { DocData_ } from '../firebase-admin/Firestore';

type TriggerCtx = {
  id: string;
  docData: DocData_;
  event: EventContext;
};

export const _document = firestore.document;

export const _onCreate =
  (builder: DocumentBuilder) =>
  (handler: (context: TriggerCtx) => Promise<unknown>) =>
    builder.onCreate(({ id, data }, event) =>
      handler({ id, docData: data(), event })
    );
